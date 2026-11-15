import 'package:avelune_studio/features/map_workspace/coordination/editor_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_selection_shortcuts.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_deletion_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_failure_message.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

Map<ShortcutActivator, VoidCallback> mapEditingShortcuts(
  MapWorkspaceController controller,
  MapWorkspaceEditingState? view,
  void Function(void Function()) guarded, {
  VoidCallback? onSave,
  VoidCallback? onUndo,
  VoidCallback? onRedo,
  void Function(void Function())? guardedWhileTyping,
  VoidCallback? onContextMenu,
  VoidCallback? onCommandPalette,
  MapContextActionContext? Function(GridPos cell)? contextAt,
}) {
  final document = controller.active;
  final project = controller.project;
  final commands = document == null || project == null
      ? null
      : MapEditingCommands(document, project);
  final selection = view == null
      ? null
      : MapSelectionActions(controller, view, contextAt: contextAt);
  void delete() {
    if (document == null || project == null) return;
    if (selection != null && selection.selection.length > 1) {
      selection.delete();
      return;
    }
    final selected = selectedContextTarget(document, project, view);
    if (selected == null) {
      commands?.deleteSelected();
      return;
    }
    final target = selected.target;
    try {
      final context =
          contextAt?.call(selected.at) ??
          MapContextActionContext(
            document: document,
            project: project,
            position: selected.at,
          );
      final blocked = mapContextDeletionProblem(context, target);
      if (blocked != null) {
        document.error = blocked;
        return;
      }
      if (target.family == MapContextFamily.character) {
        final before = document.current;
        final after = removeEntityFromMap(before, entityId: target.id);
        final problem = controller.historyGuard?.call(before, after);
        if (problem != null) {
          document.error = problem;
          return;
        }
      }
      final refusal = MapContextCommandRunner(context)
          .run(MapContextCommand.delete, target);
      if (refusal != null) {
        document.error = refusal;
        return;
      }
      view?.clearSelection(document);
    } catch (error) {
      document.error = mapFailureMessage(error);
    }
  }

  final result = <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.escape): () => guarded(() {
      if (document != null &&
          view != null &&
          view.tool == StudioMapTool.select &&
          view.pendingMove == null) {
        view.clearSelection(document);
      } else if (document != null && view != null) {
        cancelMapInput(view);
      } else {
        view?.tool = StudioMapTool.select;
      }
    }),
    if (selection != null) ...mapSelectionShortcuts(selection, guarded),
    if (onContextMenu != null)
      const SingleActivator(LogicalKeyboardKey.f10, shift: true): () =>
          guarded(onContextMenu),
    if (onContextMenu != null)
      const SingleActivator(LogicalKeyboardKey.contextMenu): () =>
          guarded(onContextMenu),
    const SingleActivator(LogicalKeyboardKey.delete): () => guarded(delete),
    const SingleActivator(LogicalKeyboardKey.backspace): () => guarded(delete),
  };
  for (final meta in [true, false]) {
    result[SingleActivator(
      LogicalKeyboardKey.keyZ,
      meta: meta,
      control: !meta,
    )] = () =>
        guarded(onUndo ?? () => controller.restore(redo: false));
    result[SingleActivator(
      LogicalKeyboardKey.keyZ,
      meta: meta,
      control: !meta,
      shift: true,
    )] = () =>
        guarded(onRedo ?? () => controller.restore(redo: true));
    result[SingleActivator(
      LogicalKeyboardKey.keyS,
      meta: meta,
      control: !meta,
    )] = () => (guardedWhileTyping ?? guarded)(() {
      if (onSave != null) {
        onSave();
      } else if (document != null) {
        unawaited(controller.save(document));
      }
    });
    if (onCommandPalette != null) {
      result[SingleActivator(
        LogicalKeyboardKey.keyK,
        meta: meta,
        control: !meta,
      )] = () =>
          guarded(onCommandPalette);
    }
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
  return textAwareEditorShortcuts(result);
}
