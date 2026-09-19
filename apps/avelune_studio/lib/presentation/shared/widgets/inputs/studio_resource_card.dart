import 'package:flutter/material.dart';
import '../layout/studio_asset_preview.dart';
import '../feedback/studio_badge.dart';
import '../../../theme/studio_tokens.dart';

class StudioResourceCard extends StatefulWidget {
  const StudioResourceCard({
    super.key,
    required this.name,
    required this.preview,
    required this.selected,
    required this.onTap,
    this.category,
    this.metadata,
  });
  final String name;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;
  final String? category, metadata;
  @override
  State<StudioResourceCard> createState() => _StudioResourceCardState();
}

class _StudioResourceCardState extends State<StudioResourceCard> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: Material(
        color: widget.selected ? c.primaryContainer : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          side: BorderSide(
            color: focused
                ? c.onSurface
                : widget.selected
                ? c.primary
                : c.outlineVariant,
            width: focused || widget.selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => focused = value),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StudioAssetPreview(child: widget.preview)),
                const SizedBox(height: 8),
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (widget.category != null) ...[
                  const SizedBox(height: 6),
                  StudioBadge(widget.category!),
                ],
                if (widget.metadata != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.metadata!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
