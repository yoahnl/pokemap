import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

class ResourceLibraryMapUsageLinks extends StatefulWidget {
  const ResourceLibraryMapUsageLinks({
    super.key,
    required this.mapIds,
    required this.maps,
    required this.emptyLabel,
    this.onOpenMap,
    this.onMapOpened,
  });

  final Iterable<String> mapIds;
  final Map<String, String> maps;
  final String emptyLabel;
  final Future<bool> Function(String)? onOpenMap;
  final VoidCallback? onMapOpened;

  @override
  State<ResourceLibraryMapUsageLinks> createState() =>
      _ResourceLibraryMapUsageLinksState();
}

class _ResourceLibraryMapUsageLinksState
    extends State<ResourceLibraryMapUsageLinks> {
  static const _visibleMaps = 6;

  String? _openingMap;
  bool _openFailed = false;
  bool _allMaps = false;

  Future<void> _openMap(String id) async {
    if (_openingMap != null) return;
    setState(() {
      _openingMap = id;
      _openFailed = false;
    });
    var opened = false;
    try {
      opened = await widget.onOpenMap!(id);
    } on Object {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _openingMap = null;
      _openFailed = !opened;
    });
    if (opened) widget.onMapOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.mapIds.toList()
      ..sort((a, b) => (widget.maps[a] ?? '').compareTo(widget.maps[b] ?? ''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ids.isEmpty)
          Text(widget.emptyLabel, style: Theme.of(context).textTheme.bodySmall),
        for (final id in _allMaps ? ids : ids.take(_visibleMaps))
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
            child: _mapLink(id),
          ),
        if (ids.length > _visibleMaps)
          StudioButton(
            label: _allMaps
                ? 'Réduire la liste'
                : 'Voir les ${ids.length} cartes',
            variant: StudioButtonVariant.quiet,
            onPressed: () => setState(() => _allMaps = !_allMaps),
          ),
        if (_openFailed)
          const StudioNotice('Impossible d’ouvrir cette carte.', isError: true),
      ],
    );
  }

  Widget _mapLink(String id) {
    final name = widget.maps[id];
    if (name == null || widget.onOpenMap == null) {
      return StudioBadge(
        name ?? 'Carte indisponible',
        icon: Icons.map_outlined,
      );
    }
    return StudioButton(
      key: ValueKey('library-map-$id'),
      label: name,
      icon: Icons.map_outlined,
      variant: StudioButtonVariant.secondary,
      loading: _openingMap == id,
      onPressed: _openingMap == null ? () => _openMap(id) : null,
    );
  }
}
