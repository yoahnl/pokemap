import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_view_data.dart';

class ResourceLibraryTile extends StatelessWidget {
  const ResourceLibraryTile({
    super.key,
    required this.item,
    required this.maps,
    required this.selected,
    required this.onSelected,
    required this.grid,
    this.preview,
  });

  final ResourceLibraryItemView item;
  final Map<String, String> maps;
  final bool selected;
  final VoidCallback onSelected;
  final bool grid;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );
    final title = Text(
      item.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall,
    );
    final type = Text(item.type, style: theme.textTheme.bodySmall);
    final usage = item.usageLabel(maps);
    final usageLine = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          item.usedOn?.isEmpty == true
              ? Icons.remove_circle_outline
              : item.usedOn == null && item.mapId == null
              ? Icons.folder_open_outlined
              : Icons.place_outlined,
          size: 14,
        ),
        const SizedBox(width: StudioSpacing.xs),
        Flexible(
          child: Text(
            usage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '${item.name}, ${item.type}, $usage',
      child: Tooltip(
        message: item.name,
        excludeFromSemantics: true,
        child: Material(
          color: colors.surface,
          shape: shape,
          borderOnForeground: true,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelected,
            child: grid
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ResourceLibraryArt(
                          item: item,
                          selected: selected,
                          preview: preview,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(StudioSpacing.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: StudioSpacing.xs),
                            type,
                            const SizedBox(height: StudioSpacing.m),
                            usageLine,
                          ],
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(StudioSpacing.m),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 62,
                          height: 48,
                          child: ResourceLibraryArt(
                            item: item,
                            showDimension: false,
                            preview: preview,
                          ),
                        ),
                        const SizedBox(width: StudioSpacing.l),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [title, type, usageLine],
                          ),
                        ),
                        if (item.dimension case final dimension?)
                          StudioBadge(dimension.label),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ResourceLibraryArt extends StatelessWidget {
  const ResourceLibraryArt({
    super.key,
    required this.item,
    this.selected = false,
    this.showDimension = true,
    this.height,
    this.preview,
  });

  final ResourceLibraryItemView item;
  final bool selected;
  final bool showDimension;
  final double? height;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        StudioAssetPreview(
          height: height,
          checkerboard: preview == null && item.art == null,
          child: preview ?? item.art ?? Icon(item.category.icon, size: 40),
        ),
        if (showDimension && item.dimension != null)
          Positioned(
            left: StudioSpacing.m,
            top: StudioSpacing.m,
            child: StudioBadge(item.dimension!.label),
          ),
        if (selected)
          Positioned(
            right: StudioSpacing.m,
            top: StudioSpacing.m,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: scheme.primary,
              child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
            ),
          ),
      ],
    );
  }
}
