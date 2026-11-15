import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_deletion.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_dialogs.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

final class MapBuilderMapLibraryActions {
  const MapBuilderMapLibraryActions({
    required this.commands,
    required this.onOpen,
    required this.onRename,
    required this.onFailure,
  });

  final MapLibraryCommands commands;
  final ValueChanged<ProjectMapEntry>? onOpen;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onFailure;

  static String mapKey(String id) => 'map:$id';
  static String folderKey(String id) => 'folder:$id';

  List<StudioContextMenuItem> addItems(
    BuildContext context, {
    String? groupId,
  }) {
    final l10n = context.l10n;
    return [
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-new-map'),
        label: groupId == null
            ? l10n.mapLibraryNewMap
            : l10n.mapLibraryNewMapHere,
        icon: Icons.add_box_outlined,
        disabledReason: _busyReason(context),
        onSelected: () => newMap(context, groupId: groupId),
      ),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-new-folder'),
        label: groupId == null
            ? l10n.mapLibraryNewFolder
            : l10n.mapLibraryNewSubfolder,
        icon: Icons.create_new_folder_outlined,
        disabledReason: _busyReason(context),
        onSelected: () => newFolder(context, parentId: groupId),
      ),
    ];
  }

  List<StudioContextMenuItem> mapItems(
    BuildContext context,
    ProjectMapEntry map, {
    required bool active,
  }) {
    final l10n = context.l10n;
    final busy = _busyReason(context);
    final open = onOpen;
    return [
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-open'),
        label: l10n.mapLibraryOpen,
        icon: Icons.open_in_new,
        onSelected: open == null || active ? null : () => open(map),
      ),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-rename'),
        label: l10n.mapLibraryRename,
        icon: Icons.edit_outlined,
        shortcut: 'F2',
        disabledReason: busy,
        onSelected: () => onRename(mapKey(map.id)),
      ),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-duplicate'),
        label: l10n.mapLibraryDuplicate,
        icon: Icons.copy_outlined,
        disabledReason: busy,
        onSelected: () => _run(
          commands.duplicateMap(
            map.id,
            name: l10n.mapLibraryCopyName(map.name),
          ),
          context,
        ),
      ),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-move'),
        label: l10n.mapLibraryMove,
        icon: Icons.drive_file_move_outlined,
        disabledReason: busy,
        onSelected: () =>
            unawaited(showMapBuilderMoveDialog(context, commands, map)),
      ),
      const StudioContextMenuSeparator(),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-delete'),
        label: l10n.mapLibraryDelete,
        icon: Icons.delete_outline,
        shortcut: '⌫',
        destructive: true,
        disabledReason: busy ?? _deletionReason(context),
        onSelected: () => deleteMap(context, map),
      ),
    ];
  }

  List<StudioContextMenuItem> folderItems(
    BuildContext context,
    ProjectMapGroup group,
  ) {
    final l10n = context.l10n;
    final busy = _busyReason(context);
    return [
      ...addItems(context, groupId: group.id),
      const StudioContextMenuSeparator(),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-rename-folder'),
        label: l10n.mapLibraryRenameFolder,
        icon: Icons.edit_outlined,
        shortcut: 'F2',
        disabledReason: busy,
        onSelected: () => onRename(folderKey(group.id)),
      ),
      StudioContextMenuEntry(
        key: const ValueKey('map-library-menu-delete-folder'),
        label: l10n.mapLibraryDeleteFolder,
        icon: Icons.folder_delete_outlined,
        destructive: true,
        disabledReason:
            busy ??
            _deletionReason(context) ??
            (commands.folderDeletionBlocked(group.id)
                ? l10n.mapLibraryFolderNotEmpty
                : null),
        onSelected: () => _run(commands.deleteFolder(group.id), context),
      ),
    ];
  }

  void newMap(BuildContext context, {String? groupId}) => unawaited(
    showMapBuilderNewMapDialog(context, commands, groupId: groupId),
  );

  void newFolder(BuildContext context, {String? parentId}) {
    final l10n = context.l10n;
    unawaited(
      showMapBuilderFolderNameDialog(
        context,
        title: l10n.mapLibraryNewFolderTitle,
        confirmLabel: l10n.mapLibraryCreate,
        onSubmit: (name) => commands.createFolder(name, parentId: parentId),
      ),
    );
  }

  void deleteMap(BuildContext context, ProjectMapEntry map) {
    if (commands.busy) return;
    if (_deletionReason(context) case final reason?) return onFailure(reason);
    unawaited(showMapBuilderDeletionDialog(context, commands, map));
  }

  void deleteRow(BuildContext context, String key) {
    final project = commands.maps.project;
    final map = project?.maps.where((m) => mapKey(m.id) == key).firstOrNull;
    if (map != null) return deleteMap(context, map);
    final group = project?.groups
        .where((g) => folderKey(g.id) == key)
        .firstOrNull;
    if (group != null) deleteFolder(context, group);
  }

  void deleteFolder(BuildContext context, ProjectMapGroup group) {
    if (_deletionReason(context) case final reason?) return onFailure(reason);
    if (commands.busy || commands.folderDeletionBlocked(group.id)) {
      onFailure(context.l10n.mapLibraryFolderNotEmpty);
      return;
    }
    _run(commands.deleteFolder(group.id), context);
  }

  Future<bool> rename(BuildContext context, String key, String name) async {
    final l10n = context.l10n;
    final outcome = key.startsWith('map:')
        ? await commands.renameMap(key.substring(4), name)
        : await commands.renameFolder(key.substring(7), name);
    if (!outcome.ok) onFailure(l10n.mapLibraryProblem(outcome));
    return outcome.ok;
  }

  void _run(Future<MapLibraryOutcome> operation, BuildContext context) {
    final l10n = context.l10n;
    unawaited(
      operation.then((outcome) {
        if (!outcome.ok) onFailure(l10n.mapLibraryProblem(outcome));
      }),
    );
  }

  String? _deletionReason(BuildContext context) =>
      commands.canDelete ? null : context.l10n.mapLibraryDeleteUnavailable;

  String? _busyReason(BuildContext context) =>
      commands.busy ? context.l10n.mapLibraryBusy : null;
}
