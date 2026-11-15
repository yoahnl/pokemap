import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/map_context_menu_actions.dart';
import '../application/map_context_deletion_guard.dart';
import '../application/map_failure_message.dart';
import '../application/map_selection_commands.dart';
import '../application/map_workspace_controller.dart';
import '../application/map_workspace_editing_state.dart';

class MapSelectionActions {
  MapSelectionActions(this.controller, this.view, {this.contextAt});
  final MapWorkspaceController controller;
  final MapWorkspaceEditingState view;
  final MapContextActionContext? Function(GridPos cell)? contextAt;

  List<MapSelectionTarget> get selection {
    final document = controller.active;
    return document == null ? const [] : view.selectionIn(document.current.id);
  }

  bool get hasClipboard => controller.clipboard != null;

  bool get canRotate {
    final instances = controller.active?.current.spatialScene?.instances;
    if (instances == null) return false;
    final ids = {for (final instance in instances) instance.id};
    return selection.any(
      (target) =>
          target.family == MapSelectionFamily.decor && ids.contains(target.id),
    );
  }

  MapContextDeletionGuard? get _guard {
    final context = contextAt?.call(const GridPos(x: 0, y: 0));
    return context == null
        ? null
        : (target) => mapContextDeletionProblem(context, target);
  }

  void _run(
    void Function(MapSelectionCommands commands) action, {
    bool guardHistory = false,
  }) {
    final document = controller.active;
    final project = controller.project;
    if (document == null || project == null) return;
    try {
      action(
        MapSelectionCommands(
          document,
          project,
          historyGuard: guardHistory ? controller.historyGuard : null,
        ),
      );
    } catch (failure) {
      document.error = mapFailureMessage(failure);
    }
  }

  void _select(List<MapSelectionTarget> targets) {
    final document = controller.active;
    if (document != null) view.selectAll(document, targets);
  }

  bool get _touchesCharacters =>
      selection.any((target) => target.family == MapSelectionFamily.character);

  void copy() {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) => controller.clipboard = commands.copy(targets));
  }

  void cut() {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) {
      controller.clipboard = commands.cut(targets, guard: _guard);
      _select(const []);
    }, guardHistory: _touchesCharacters);
  }

  Future<void> paste({GridPos? at}) async {
    final clipboard = controller.clipboard;
    final document = controller.active;
    final project = controller.project;
    if (clipboard == null || document == null || project == null) return;
    final missing = [
      for (final (kind, id) in clipboard.definitions)
        if (!definesClipboardResource(project, kind, id)) (kind, id),
    ];
    if (missing.isNotEmpty) {
      try {
        for (final (kind, id) in missing) {
          await controller.ensureResourceClosure(kind, id);
        }
      } catch (failure) {
        document.error = mapFailureMessage(failure);
        controller.notify();
        return;
      }
      if (!identical(controller.active, document)) return;
    }
    final pointer = view.pointer;
    final cell =
        at ?? (pointer?.mapId == document.current.id ? pointer!.cell : null);
    _run((commands) => _select(commands.paste(clipboard, at: cell)));
    if (missing.isNotEmpty) controller.notify();
  }

  void duplicate() {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) => _select(commands.duplicate(targets)));
  }

  void delete() {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) {
      commands.delete(targets, guard: _guard);
      _select(const []);
    }, guardHistory: _touchesCharacters);
  }

  void move(int dx, int dy) {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) => commands.move(targets, dx, dy));
  }

  void rotate() {
    final targets = selection;
    if (targets.isEmpty) return;
    _run((commands) => commands.rotate(targets, 90));
  }
}

Map<ShortcutActivator, VoidCallback> mapSelectionShortcuts(
  MapSelectionActions actions,
  void Function(void Function()) guarded,
) => {
  for (final meta in [true, false]) ...{
    SingleActivator(LogicalKeyboardKey.keyC, meta: meta, control: !meta): () =>
        guarded(actions.copy),
    SingleActivator(LogicalKeyboardKey.keyX, meta: meta, control: !meta): () =>
        guarded(actions.cut),
    SingleActivator(LogicalKeyboardKey.keyV, meta: meta, control: !meta): () =>
        guarded(actions.paste),
    SingleActivator(LogicalKeyboardKey.keyD, meta: meta, control: !meta): () =>
        guarded(actions.duplicate),
  },
  for (final (key, dx, dy) in [
    (LogicalKeyboardKey.arrowLeft, -1, 0),
    (LogicalKeyboardKey.arrowRight, 1, 0),
    (LogicalKeyboardKey.arrowUp, 0, -1),
    (LogicalKeyboardKey.arrowDown, 0, 1),
  ])
    SingleActivator(key): () => guarded(() => actions.move(dx, dy)),
};
