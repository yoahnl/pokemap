import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/map_context_command.dart';
import 'map_context_menu_controller.dart';

typedef MapContextCommandSelected = Future<void> Function(
  MapContextCommand command,
  MapContextMenuOpen menu,
);

const _commandFailureMessage = 'Impossible d’exécuter cette action. Réessayez.';

/// Renders the one controlled World Map context menu.
///
/// This widget must be a direct child of the workspace [Stack]. It consumes
/// only the frozen controller snapshot and never reads or mutates editor state.
class MapContextMenuHost extends ConsumerWidget {
  const MapContextMenuHost({
    required this.onCommandSelected,
    this.onCommandRejected,
    super.key,
  });

  final MapContextCommandSelected onCommandSelected;
  final ValueChanged<String>? onCommandRejected;

  Future<void> _runCommand(
    MapContextCommand command,
    MapContextMenuOpen menu,
  ) async {
    try {
      await onCommandSelected(command, menu);
    } on Object {
      onCommandRejected?.call(_commandFailureMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapContextMenuControllerProvider);
    final controller = ref.read(mapContextMenuControllerProvider.notifier);
    return Positioned.fill(
      child: switch (state) {
        MapContextMenuClosed() => const SizedBox.shrink(),
        final MapContextMenuOpen open => LayoutBuilder(
            builder: (context, constraints) {
              final renderObject = context.findRenderObject();
              final anchor = renderObject is RenderBox
                  ? renderObject.globalToLocal(open.anchor)
                  : open.anchor;
              final dividerAfter = <int>{
                for (var index = 1; index < open.entries.length; index += 1)
                  if (open.entries[index].startsSection) index - 1,
              };
              return Stack(
                fit: StackFit.expand,
                children: [
                  PokeMapContextMenu<MapContextCommand>(
                    anchor: anchor,
                    items: <PokeMapMenuItem<MapContextCommand>>[
                      for (final entry in open.entries)
                        PokeMapMenuItem<MapContextCommand>(
                          value: entry.command,
                          label: entry.label,
                          shortcutLabel: entry.shortcutLabel,
                          enabled: entry.enabled,
                          disabledReason: entry.disabledReason,
                          destructive: entry.destructive,
                        ),
                    ],
                    dividerAfter: dividerAfter,
                    invokerFocusNode: controller.invokerFocusNode,
                    semanticLabel: 'Actions contextuelles de la carte',
                    onDismiss: controller.close,
                    onSelected: (command) {
                      unawaited(_runCommand(command, open));
                    },
                  ),
                ],
              );
            },
          ),
      },
    );
  }
}
