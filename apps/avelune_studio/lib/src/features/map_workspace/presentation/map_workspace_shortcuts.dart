import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../application/map_workspace_controller.dart';
import '../application/map_editing_commands.dart';
import 'map_workspace_view_state.dart';

Map<ShortcutActivator, VoidCallback> workspaceShortcuts(
  MapWorkspaceController controller,
  MapWorkspaceViewState? view,
  void Function(void Function()) guarded,
) {
  final document = controller.active;
  final project = controller.project;
  final commands = document == null || project == null
      ? null
      : MapEditingCommands(document, project);
  final result = <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.escape): () => guarded(() {
      view?.tool = StudioMapTool.select;
    }),
    const SingleActivator(LogicalKeyboardKey.delete): () =>
        guarded(() => commands?.deleteSelected()),
    const SingleActivator(LogicalKeyboardKey.backspace): () =>
        guarded(() => commands?.deleteSelected()),
  };
  for (final meta in [true, false]) {
    result[SingleActivator(
      LogicalKeyboardKey.keyZ,
      meta: meta,
      control: !meta,
    )] = () =>
        guarded(() => document?.restore(redo: false));
    result[SingleActivator(
      LogicalKeyboardKey.keyZ,
      meta: meta,
      control: !meta,
      shift: true,
    )] = () =>
        guarded(() => document?.restore(redo: true));
    result[SingleActivator(
      LogicalKeyboardKey.keyS,
      meta: meta,
      control: !meta,
    )] = () => guarded(() {
      if (document != null) unawaited(controller.save(document));
    });
    result[SingleActivator(
      LogicalKeyboardKey.arrowUp,
      meta: meta,
      control: !meta,
    )] = () =>
        guarded(() => commands?.reorder(forward: true));
    result[SingleActivator(
      LogicalKeyboardKey.arrowDown,
      meta: meta,
      control: !meta,
    )] = () =>
        guarded(() => commands?.reorder(forward: false));
  }
  return result;
}
