import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_tree.dart';

const mapBuilderLibraryWidth = 304.0;

enum _LibraryTab { resources, maps }

class MapBuilderLibrary extends StatefulWidget {
  const MapBuilderLibrary({
    super.key,
    required this.groups,
    required this.maps,
    required this.activeMapId,
    required this.onSelectMap,
    required this.resources,
  });

  final List<ProjectMapGroup> groups;
  final List<ProjectMapEntry> maps;
  final String? activeMapId;
  final ValueChanged<ProjectMapEntry>? onSelectMap;
  final Widget resources;

  @override
  State<MapBuilderLibrary> createState() => _MapBuilderLibraryState();
}

class _MapBuilderLibraryState extends State<MapBuilderLibrary> {
  var _tab = _LibraryTab.resources;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Ink(
      key: const ValueKey('map-library'),
      width: mapBuilderLibraryWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.m),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                _LibraryTabButton(
                  label: 'Ressources',
                  selected: _tab == _LibraryTab.resources,
                  onTap: () => setState(() => _tab = _LibraryTab.resources),
                ),
                _LibraryTabButton(
                  label: 'Cartes',
                  selected: _tab == _LibraryTab.maps,
                  onTap: () => setState(() => _tab = _LibraryTab.maps),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _LibraryTab.resources => widget.resources,
              _LibraryTab.maps => MapBuilderMapTree(
                groups: widget.groups,
                maps: widget.maps,
                activeMapId: widget.activeMapId,
                onSelect: widget.onSelectMap,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _LibraryTabButton extends StatelessWidget {
  const _LibraryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('map-library-tab-$label'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
