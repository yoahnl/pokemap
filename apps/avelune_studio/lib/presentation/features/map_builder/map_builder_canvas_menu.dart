import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_selection_shortcuts.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:map_core/map_core_domain.dart';

const _specificCommands = {
  MapContextCommand.move,
  MapContextCommand.bringForward,
  MapContextCommand.sendBackward,
};

List<StudioContextMenuItem> mapBuilderCanvasMenu({
  required AppLocalizations l10n,
  required MapSelectionActions actions,
  required GridPos cell,
  required MapContextTarget? target,
  required List<MapContextAction> targetActions,
  required VoidCallback onProperties,
  required void Function(MapContextCommand command) onCommand,
  required VoidCallback changed,
}) {
  VoidCallback act(VoidCallback action) => () {
    action();
    changed();
  };
  final paste = StudioContextMenuEntry(
    key: const ValueKey('map-menu-paste'),
    label: l10n.mapMenuPaste,
    icon: Icons.content_paste,
    shortcut: '⌘V',
    disabledReason: actions.hasClipboard ? null : l10n.mapMenuClipboardEmpty,
    onSelected: act(() => actions.paste(at: cell)),
  );
  if (target == null) return [paste];
  final single = actions.selection.length <= 1;
  final deletion = single
      ? targetActions
            .where((action) => action.command == MapContextCommand.delete)
            .firstOrNull
      : null;
  final specific = single
      ? [
          for (final action in targetActions)
            if (_specificCommands.contains(action.command)) action,
        ]
      : const <MapContextAction>[];
  return [
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-cut'),
      label: l10n.mapMenuCut,
      icon: Icons.content_cut,
      shortcut: '⌘X',
      disabledReason: deletion?.unavailable,
      onSelected: act(actions.cut),
    ),
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-copy'),
      label: l10n.mapMenuCopy,
      icon: Icons.content_copy,
      shortcut: '⌘C',
      onSelected: act(actions.copy),
    ),
    paste,
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-duplicate'),
      label: l10n.mapMenuDuplicate,
      icon: Icons.control_point_duplicate,
      shortcut: '⌘D',
      onSelected: act(actions.duplicate),
    ),
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-delete'),
      label: l10n.mapMenuDelete,
      icon: Icons.delete_outline,
      shortcut: '⌫',
      destructive: true,
      disabledReason: deletion?.unavailable,
      onSelected: act(actions.delete),
    ),
    const StudioContextMenuSeparator(),
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-rotate'),
      label: l10n.mapMenuRotate,
      icon: Icons.rotate_90_degrees_cw_outlined,
      disabledReason: actions.canRotate ? null : l10n.mapMenuRotateUnavailable,
      onSelected: act(actions.rotate),
    ),
    StudioContextMenuEntry(
      key: const ValueKey('map-menu-properties'),
      label: l10n.mapMenuProperties,
      icon: Icons.tune,
      onSelected: onProperties,
    ),
    if (specific.isNotEmpty) const StudioContextMenuSeparator(),
    for (final action in specific)
      StudioContextMenuEntry(
        key: ValueKey('map-menu-${action.command.name}'),
        label: switch (action.command) {
          MapContextCommand.bringForward => l10n.mapMenuBringForward,
          MapContextCommand.sendBackward => l10n.mapMenuSendBackward,
          _ => l10n.mapMenuMove,
        },
        icon: switch (action.command) {
          MapContextCommand.bringForward => Icons.flip_to_front,
          MapContextCommand.sendBackward => Icons.flip_to_back,
          _ => Icons.open_with,
        },
        disabledReason: action.unavailable,
        onSelected: act(() => onCommand(action.command)),
      ),
  ];
}
