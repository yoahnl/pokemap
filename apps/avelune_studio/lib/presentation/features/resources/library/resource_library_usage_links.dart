import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_view_data.dart';

class ResourceLibraryUsageLinks extends StatefulWidget {
  const ResourceLibraryUsageLinks({
    super.key,
    required this.item,
    required this.maps,
    required this.source,
    required this.consumers,
    required this.revision,
    required this.loadRelations,
    required this.onRelated,
    required this.onOpenMap,
    required this.onMapOpened,
  });

  final ResourceLibraryItemView item;
  final Map<String, String> maps;
  final ResourceLibraryItemView? source;
  final List<ResourceLibraryItemView> consumers;
  final String? revision;
  final Future<ResourceLibraryRelationsView?> Function()? loadRelations;
  final ValueChanged<ResourceLibraryItemView> onRelated;
  final Future<bool> Function(String)? onOpenMap;
  final VoidCallback? onMapOpened;

  @override
  State<ResourceLibraryUsageLinks> createState() =>
      _ResourceLibraryUsageLinksState();
}

class _ResourceLibraryUsageLinksState extends State<ResourceLibraryUsageLinks> {
  static const _visibleMaps = 6;
  Future<ResourceLibraryRelationsView?>? _relations;
  String? _openingMap;
  bool _openFailed = false;
  bool _allMaps = false;

  @override
  void initState() {
    super.initState();
    _relations = widget.loadRelations?.call();
  }

  @override
  void didUpdateWidget(ResourceLibraryUsageLinks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.item.id != widget.item.id ||
        (oldWidget.loadRelations == null) != (widget.loadRelations == null)) {
      _relations = widget.loadRelations?.call();
    }
  }

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
    final theme = Theme.of(context);
    final usedOn = widget.item.usedOn;
    final maps = [...?usedOn]
      ..sort((a, b) => (widget.maps[a] ?? '').compareTo(widget.maps[b] ?? ''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usedOn == null ? 'Disponibilité' : 'Utilisation dans les cartes',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: StudioSpacing.m),
        if (maps.isEmpty)
          Text(
            widget.item.usageLabel(widget.maps),
            style: theme.textTheme.bodySmall,
          ),
        for (final id in _allMaps ? maps : maps.take(_visibleMaps))
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
            child: _mapLink(id),
          ),
        if (maps.length > _visibleMaps)
          StudioButton(
            label: _allMaps
                ? 'Réduire la liste'
                : 'Voir les ${maps.length} cartes',
            variant: StudioButtonVariant.quiet,
            onPressed: () => setState(() => _allMaps = !_allMaps),
          ),
        if (_openFailed)
          const StudioNotice('Impossible d’ouvrir cette carte.', isError: true),
        if (_relations == null)
          _related(
            context,
            sources: [?widget.source],
            consumers: widget.consumers,
          )
        else
          FutureBuilder<ResourceLibraryRelationsView?>(
            future: _relations,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.only(top: StudioSpacing.l),
                  child: Text('Recherche des ressources liées…'),
                );
              }
              final relations = snapshot.data;
              if (relations == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: StudioSpacing.l),
                  child: StudioNotice(
                    'Liens indisponibles. Actualisez la bibliothèque.',
                  ),
                );
              }
              return _related(
                context,
                sources: relations.sources,
                consumers: relations.consumers,
              );
            },
          ),
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

  Widget _related(
    BuildContext context, {
    required List<ResourceLibraryItemView> sources,
    required List<ResourceLibraryItemView>? consumers,
  }) {
    final title = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sources.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.xl),
          Text(
            sources.length == 1 ? 'Source associée' : 'Sources associées',
            style: title,
          ),
          const SizedBox(height: StudioSpacing.m),
          for (final item in sources) _relatedButton(item),
        ],
        if (consumers == null) ...[
          const SizedBox(height: StudioSpacing.l),
          const StudioNotice(
            'L’index des usages entre ressources n’est pas préparé.',
          ),
        ] else if (consumers.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.xl),
          Text('Ressources qui l’utilisent', style: title),
          const SizedBox(height: StudioSpacing.m),
          for (final item in consumers) _relatedButton(item),
        ],
      ],
    );
  }

  Widget _relatedButton(ResourceLibraryItemView target) => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
    child: StudioButton(
      key: ValueKey('library-source-${target.id}'),
      label: target.name,
      icon: Icons.link,
      secondary: true,
      onPressed: () => widget.onRelated(target),
    ),
  );
}
