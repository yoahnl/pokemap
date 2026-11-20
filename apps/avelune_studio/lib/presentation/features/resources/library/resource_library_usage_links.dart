import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_map_usage_links.dart';
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
  Future<ResourceLibraryRelationsView?>? _relations;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedOn = widget.item.usedOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usedOn == null ? 'Disponibilité' : 'Utilisation dans les cartes',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: StudioSpacing.m),
        ResourceLibraryMapUsageLinks(
          mapIds: usedOn ?? const <String>{},
          maps: widget.maps,
          emptyLabel: widget.item.usageLabel(widget.maps),
          onOpenMap: widget.onOpenMap,
          onMapOpened: widget.onMapOpened,
        ),
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
