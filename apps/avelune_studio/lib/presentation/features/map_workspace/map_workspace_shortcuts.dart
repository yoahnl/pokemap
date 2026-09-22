import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_context.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

Map<ShortcutActivator, VoidCallback> workspaceShortcuts(
  MapWorkspaceController controller,
  MapWorkspaceViewState? view,
  void Function(void Function()) guarded, {
  VoidCallback? onSave,
  void Function(void Function())? guardedWhileTyping,
  VoidCallback? onContextMenu,
  MapContextActionContext? Function(GridPos cell)? contextAt,
}) {
  final document = controller.active;
  final project = controller.project;
  final commands = document == null || project == null
      ? null
      : MapEditingCommands(document, project);
  final characters = document == null || project == null
      ? null
      : CharacterEditingCommands(document, project);
  void delete() {
    if (document == null || project == null) return;
    final selected = selectedContextTarget(document, project, view);
    if (selected == null) {
      commands?.deleteSelected();
      return;
    }
    final target = selected.target;
    try {
      if (target.family == MapContextFamily.character) {
        final before = document.current;
        final after = removeEntityFromMap(before, entityId: target.id);
        final problem = controller.historyGuard?.call(before, after);
        if (problem != null) {
          document.error = problem;
          return;
        }
      }
      final refusal = MapContextCommandRunner(
        contextAt?.call(selected.at) ??
            MapContextActionContext(
              document: document,
              project: project,
              position: selected.at,
            ),
      ).run(MapContextCommand.delete, target);
      if (refusal != null) {
        document.error = refusal;
        return;
      }
      view?.clearSelection(document);
    } catch (error) {
      document.error = error.toString();
    }
  }

  void cancelPending() {
    if (document != null) view?.pendingMove = null;
  }

  final result = <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.escape): () => guarded(() {
      cancelPending();
      view?.tool = StudioMapTool.select;
    }),
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
        guarded(() => controller.restore(redo: false));
    result[SingleActivator(
      LogicalKeyboardKey.keyZ,
      meta: meta,
      control: !meta,
      shift: true,
    )] = () =>
        guarded(() => controller.restore(redo: true));
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
    result[SingleActivator(
      LogicalKeyboardKey.keyD,
      meta: meta,
      control: !meta,
    )] = () => guarded(() {
      final id = document == null
          ? null
          : view?.selectedFor(
              document.current.id,
              MapSelectionFamily.character,
            );
      if (id != null && characters?.selected(id) != null) {
        view!.select(
          document!,
          MapSelectionFamily.character,
          characters!.duplicate(id).id,
        );
      }
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
