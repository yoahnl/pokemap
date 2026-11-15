import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';

class MapBuilderTreeRow extends StatelessWidget {
  const MapBuilderTreeRow({
    super.key,
    required this.rowKey,
    required this.tile,
    this.menu,
    this.onPointerDown,
  });

  final String rowKey;
  final Widget tile;
  final List<StudioContextMenuItem> Function()? menu;
  final ValueChanged<String>? onPointerDown;

  @override
  Widget build(BuildContext context) {
    final menu = this.menu;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kPrimaryButton) onPointerDown?.call(rowKey);
      },
      child: GestureDetector(
        onSecondaryTapUp: menu == null
            ? null
            : (details) => StudioContextMenu.showAt(
                context,
                position: details.globalPosition,
                items: menu(),
              ),
        child: tile,
      ),
    );
  }
}

class MapBuilderRenameField extends StatefulWidget {
  const MapBuilderRenameField({
    super.key,
    required this.initial,
    required this.label,
    required this.onCommit,
    required this.onCancel,
  });

  final String initial;
  final String label;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  @override
  State<MapBuilderRenameField> createState() => _MapBuilderRenameFieldState();
}

class _MapBuilderRenameFieldState extends State<MapBuilderRenameField> {
  late final _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  final _focus = FocusNode(debugLabel: 'map-library-rename');
  var _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _finish(bool commit) {
    if (_done) return;
    _done = true;
    commit ? widget.onCommit(_text.text) : widget.onCancel();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () => _finish(false),
    },
    child: TextField(
      key: const ValueKey('map-library-rename-field'),
      controller: _text,
      focusNode: _focus,
      style: Theme.of(context).textTheme.bodyMedium,
      onSubmitted: (_) => _finish(true),
      onTapOutside: (_) => _finish(true),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.s,
          vertical: StudioSpacing.xs,
        ),
      ),
    ),
  );
}

class MapBuilderFolderTile extends StatelessWidget {
  const MapBuilderFolderTile({
    super.key,
    required this.row,
    required this.open,
    required this.selected,
    this.onTap,
    this.rename,
    this.trailing,
  });

  final MapLibraryRow row;
  final bool open;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? rename;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      key: ValueKey('map-library-folder-${row.folderId ?? 'unfiled'}'),
      dense: true,
      selected: selected,
      selectedTileColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.onSurface,
      contentPadding: EdgeInsets.only(
        left: StudioSpacing.s + row.depth * StudioSpacing.xl,
        right: StudioSpacing.m,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
      leading: Icon(
        open ? Icons.folder_open_outlined : Icons.folder_outlined,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      title:
          rename ??
          Text(
            row.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${row.count}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: StudioSpacing.xs),
            trailing,
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class MapBuilderMapTile extends StatelessWidget {
  const MapBuilderMapTile({
    super.key,
    required this.row,
    required this.title,
    required this.subtitle,
    required this.mapId,
    required this.active,
    this.onTap,
    this.rename,
    this.trailing,
  });

  final MapLibraryRow row;
  final String title;
  final String subtitle;
  final String mapId;
  final bool active;
  final VoidCallback? onTap;
  final Widget? rename;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      key: ValueKey('map-library-map-$mapId'),
      dense: true,
      selected: active,
      selectedTileColor: scheme.primaryContainer,
      selectedColor: scheme.onPrimaryContainer,
      contentPadding: EdgeInsets.only(
        left: StudioSpacing.s + row.depth * StudioSpacing.xl,
        right: StudioSpacing.m,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
      leading: const Icon(Icons.map_outlined, size: 18),
      title: rename ?? Text(title, style: theme.textTheme.bodyMedium),
      subtitle: rename == null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

Set<String> mapTreeFoldersAbove(
  List<MapLibraryRow> rows,
  String mapId,
  String Function(MapLibraryRow) folderKey,
) {
  final folders = <String>{};
  final index = rows.indexWhere((row) => row.map?.id == mapId);
  if (index < 0) return folders;
  var depth = rows[index].depth;
  for (var i = index - 1; i >= 0 && depth > 0; i--) {
    if (rows[i].isFolder && rows[i].depth < depth) {
      folders.add(folderKey(rows[i]));
      depth = rows[i].depth;
    }
  }
  return folders;
}

List<MapLibraryRow> mapTreeVisibleRows(
  List<MapLibraryRow> rows,
  Set<String> expanded,
  String Function(MapLibraryRow) folderKey,
) {
  final visible = <MapLibraryRow>[];
  int? hiddenBelow;
  for (final row in rows) {
    if (hiddenBelow != null && row.depth > hiddenBelow) continue;
    hiddenBelow = null;
    visible.add(row);
    if (row.isFolder && !expanded.contains(folderKey(row))) {
      hiddenBelow = row.depth;
    }
  }
  return visible;
}
