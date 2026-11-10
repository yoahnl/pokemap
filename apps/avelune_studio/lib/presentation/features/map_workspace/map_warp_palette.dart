import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering show ScrollCacheExtent;
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/resources/domain/studio_search_text.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';

class MapWarpPalette extends StatefulWidget {
  const MapWarpPalette({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.onPick,
    this.groups = const [],
    this.arrivalSelected = false,
    this.onPickArrival,
  });
  final List<ProjectMapEntry> destinations;
  final List<ProjectMapGroup> groups;
  final String? selectedId;
  final ValueChanged<ProjectMapEntry> onPick;
  final bool arrivalSelected;
  final VoidCallback? onPickArrival;

  @override
  State<MapWarpPalette> createState() => _MapWarpPaletteState();
}

class _MapWarpPaletteState extends State<MapWarpPalette> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.bodySmall;
    final selectedId = widget.selectedId;
    final onPick = widget.onPick;
    final onPickArrival = widget.onPickArrival;
    final arrivalSelected = widget.arrivalSelected;
    final folders = mapLibraryFolderLabels(widget.groups);
    String folderOf(ProjectMapEntry entry) =>
        folders[entry.groupId ?? ''] ?? folders['']!;
    final destinations = [
      for (final entry in widget.destinations)
        if (studioSearchMatches(
          '${folderOf(entry)} ${entry.name} ${entry.id}',
          _query.text,
        ))
          entry,
    ];
    return CustomScrollView(
      key: const PageStorageKey('warp-destinations'),
      scrollCacheExtent: const rendering.ScrollCacheExtent.pixels(0),
      slivers: [
        if (onPickArrival != null)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 104,
                  child: StudioPaletteCard(
                    key: const ValueKey('warp-arrival-point'),
                    name: 'Point d’arrivée',
                    selected: arrivalSelected,
                    preview: const Icon(Icons.location_on_outlined, size: 48),
                    onTap: onPickArrival,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Utilisé par une scène', style: caption),
                const SizedBox(height: 12),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.destinations.length > 6) ...[
                  StudioSearchField(
                    key: const ValueKey('warp-destination-filter'),
                    controller: _query,
                    label: 'Rechercher une carte ou un dossier',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                ],
                Text('${destinations.length} destination(s)', style: caption),
              ],
            ),
          ),
        ),
        if (destinations.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: StudioEmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'Aucun passage vers une autre carte',
              description: 'Le point d’arrivée peut être posé sur cette carte.',
            ),
          )
        else
          SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent:
                  104 + 16 * (MediaQuery.textScalerOf(context).scale(1) - 1),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final entry = destinations[index];
              return Tooltip(
                message: '${entry.name}\n${folderOf(entry)}',
                waitDuration: const Duration(milliseconds: 500),
                child: StudioPaletteCard(
                  key: ValueKey('warp-destination-${entry.id}'),
                  name: entry.name,
                  selected: selectedId == entry.id,
                  maxNameLines: 2,
                  preview: const Icon(Icons.meeting_room_outlined, size: 48),
                  onTap: () => onPick(entry),
                ),
              );
            },
          ),
      ],
    );
  }
}
