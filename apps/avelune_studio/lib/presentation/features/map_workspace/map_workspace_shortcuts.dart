import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

Map<ShortcutActivator, VoidCallback> workspaceShortcuts(
  MapWorkspaceController controller,
  MapWorkspaceViewState? view,
  void Function(void Function()) guarded, {
  VoidCallback? onSave,
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
    final id = document == null
        ? null
        : view?.selectedFor(document.current.id, MapSelectionFamily.character);
    if (id == null || characters?.selected(id) == null) {
      commands?.deleteSelected();
      return;
    }
    try {
      final before = document!.current;
      final after = removeEntityFromMap(before, entityId: id);
      final problem = controller.historyGuard?.call(before, after);
      if (problem != null) {
        document.error = problem;
        return;
      }
      characters!.delete(id);
      view!.clearSelection(document);
    } catch (error) {
      document!.error = error.toString();
    }
  }

  final result = <ShortcutActivator, VoidCallback>{
    const SingleActivator(LogicalKeyboardKey.escape): () => guarded(() {
      view?.tool = StudioMapTool.select;
    }),
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
    )] = () => guarded(() {
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
