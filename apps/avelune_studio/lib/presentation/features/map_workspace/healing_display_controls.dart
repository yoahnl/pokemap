import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class HealingDisplayControls extends StatefulWidget {
  const HealingDisplayControls({
    super.key,
    required this.entity,
    required this.project,
    required this.onChanged,
    this.elementPreview,
  });
  final MapEntity entity;
  final ProjectManifest project;
  final ValueChanged<MapEntityHealingDisplayData?> onChanged;
  final Widget Function(ProjectElementEntry)? elementPreview;
  @override
  State<HealingDisplayControls> createState() => _HealingDisplayControlsState();
}

class _HealingDisplayControlsState extends State<HealingDisplayControls> {
  late List<String?> _variants;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(HealingDisplayControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id ||
        widget.entity.healingDisplay != oldWidget.entity.healingDisplay) {
      _reset();
    }
  }

  void _reset() {
    _variants =
        widget.entity.healingDisplay?.variantElementIds
            .cast<String?>()
            .toList() ??
        List<String?>.filled(6, null);
  }

  (int, int)? _geometry(ProjectElementEntry element) {
    if (element.frames.isEmpty ||
        element.collisionProfile != null ||
        widget.project.elements.where((e) => e.id == element.id).length != 1) {
      return null;
    }
    (int, int)? size;
    for (final frame in element.frames) {
      final id = frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId;
      final sources = widget.project.tilesets.where((t) => t.id == id).toList();
      if (sources.length != 1 ||
          sources.single.source is! ProjectRegularAtlasTilesetSource ||
          (frame.durationMs != null && frame.durationMs! <= 0)) {
        return null;
      }
      final source = sources.single.source! as ProjectRegularAtlasTilesetSource;
      try {
        final bounds = const ProjectTilesetVisualResolver()
            .resolve(
              source: source,
              selection: ProjectTilesetVisualSelection.regularAtlas(
                source: frame.source,
              ),
              cellWidth: source.tileWidth,
              cellHeight: source.tileHeight,
            )
            .animationBounds;
        final next = (bounds.width, bounds.height);
        if (bounds.width > 512 ||
            bounds.height > 512 ||
            (size != null && size != next)) {
          return null;
        }
        size = next;
      } on ProjectTilesetVisualResolutionException {
        return null;
      }
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final candidates = <String, ProjectElementEntry>{};
    final geometry = <(int, int), int>{};
    for (final element in widget.project.elements) {
      final size = _geometry(element);
      if (size == null) {
        continue;
      }
      candidates[element.id] = element;
      geometry[size] = (geometry[size] ?? 0) + 1;
    }
    candidates.removeWhere(
      (id, element) => (geometry[_geometry(element)] ?? 0) < 6,
    );
    final selected = _variants
        .whereType<String>()
        .map((id) => candidates[id])
        .whereType<ProjectElementEntry>()
        .firstOrNull;
    final size = selected == null ? null : _geometry(selected);
    final valid =
        _variants.every(
          (id) =>
              id != null &&
              candidates.containsKey(id) &&
              (size == null || _geometry(candidates[id]!) == size),
        ) &&
        _variants.toSet().length == 6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Affichage des boules de soin'),
        const SizedBox(height: 6),
        const Text(
          'Choisissez une variante pour chaque taille d’équipe. Le soin natif affiche uniquement le nombre de Pokémon présents.',
        ),
        if (candidates.length < 6)
          const Text(
            'Ajoutez six éléments visuels sans collision et de dimensions identiques à la bibliothèque.',
          ),
        for (var i = 0; i < 6; i++) ...[
          const SizedBox(height: 10),
          StudioSelect(
            key: ValueKey('healing-display-variant-$i'),
            label: '${i + 1} Pokémon',
            value: _variants[i],
            options: {
              for (final entry in candidates.entries)
                if (size == null || _geometry(entry.value) == size)
                  entry.key: entry.value.name,
            },
            onChanged: (id) => setState(() => _variants[i] = id),
          ),
          if (candidates[_variants[i]] case final element?
              when widget.elementPreview != null)
            SizedBox(
              height: 64,
              child: Center(child: widget.elementPreview!(element)),
            ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('healing-display-apply'),
          label: widget.entity.healingDisplay == null
              ? 'Utiliser cet affichage de soin'
              : 'Appliquer les variantes',
          onPressed: valid
              ? () => widget.onChanged(
                  MapEntityHealingDisplayData(
                    variantElementIds: _variants.cast<String>(),
                  ),
                )
              : null,
        ),
        if (widget.entity.healingDisplay != null) ...[
          const SizedBox(height: 8),
          StudioButton(
            key: const ValueKey('healing-display-clear'),
            label: 'Retirer l’affichage de soin',
            secondary: true,
            onPressed: () => widget.onChanged(null),
          ),
        ],
      ],
    );
  }
}
