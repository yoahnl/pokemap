import 'package:flutter/material.dart';

class StudioSection extends StatefulWidget {
  const StudioSection({
    super.key,
    required this.title,
    required this.children,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
  });
  final String title;
  final List<Widget> children;
  final bool collapsible, initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<StudioSection> createState() => _StudioSectionState();
}

class _StudioSectionState extends State<StudioSection> {
  final _privateStorage = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    if (widget.collapsible) {
      final tile = ExpansionTile(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: widget.onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.all(12),
        children: widget.children,
      );
      if (widget.key is PageStorageKey) return tile;
      return PageStorage(bucket: _privateStorage, child: tile);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...widget.children,
        ],
      ),
    );
  }
}
