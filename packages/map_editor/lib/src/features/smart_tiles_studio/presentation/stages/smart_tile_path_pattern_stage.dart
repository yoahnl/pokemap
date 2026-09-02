import 'package:flutter/cupertino.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_path_pattern.dart';
import '../workbench/smart_tile_coverage_gallery.dart';

class SmartTilePathPatternStage extends StatelessWidget {
  const SmartTilePathPatternStage({
    super.key,
    required this.selectedPatternId,
    required this.onPatternSelected,
    required this.onUseCustomPattern,
    required this.onContinue,
  });

  final SmartTilePathPatternId? selectedPatternId;
  final ValueChanged<SmartTilePathPatternId> onPatternSelected;
  final VoidCallback onUseCustomPattern;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Choisir un patron de chemin',
          description:
              'Choisissez la forme que vous voulez dessiner. PokeMap préparera les raccords tout seul.',
          trailing: const PokeMapBadge(
            label: '2 patrons disponibles',
            variant: PokeMapBadgeVariant.info,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 700
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final pattern in smartTilePathPatterns)
                  SizedBox(
                    width: itemWidth,
                    child: PokeMapAssetCard(
                      key: Key('smart-tiles-path-pattern-${pattern.id.name}'),
                      thumbnail: _PathPatternThumbnail(pattern: pattern),
                      label: pattern.label,
                      description: pattern.description,
                      selected: selectedPatternId == pattern.id,
                      onPressed: () => onPatternSelected(pattern.id),
                      trailing: selectedPatternId == pattern.id
                          ? const PokeMapBadge(
                              label: 'Choisi',
                              variant: PokeMapBadgeVariant.success,
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-path-pattern-custom'),
            onPressed: onUseCustomPattern,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.slider_horizontal_3, size: 14),
            child: const Text('Utiliser un patron personnalisé…'),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-path-pattern-continue'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Remplir ce patron'),
          ),
        ),
      ],
    );
  }
}

class _PathPatternThumbnail extends StatelessWidget {
  const _PathPatternThumbnail({required this.pattern});

  final SmartTilePathPattern pattern;

  @override
  Widget build(BuildContext context) {
    final samples = pattern.id == SmartTilePathPatternId.classic
        ? <int>[0xA, 0x3, 0xF, 0x0]
        : <int>[0x40, 0xC0, 0xF0, 0xE0];
    return SizedBox(
      width: 112,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          for (final mask in samples)
            SmartTileFormGlyph(
              mask: mask,
              topology: pattern.configuration.topology,
              dimension: 24,
            ),
        ],
      ),
    );
  }
}
