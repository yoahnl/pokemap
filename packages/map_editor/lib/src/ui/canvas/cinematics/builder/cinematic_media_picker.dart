import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../design_system/design_system.dart';
import '../../../../theme/theme.dart';

/// No-code selector for a typed cinematic media definition.
///
/// Paths and technical identifiers deliberately stay hidden from authors.
final class CinematicMediaPicker extends StatelessWidget {
  const CinematicMediaPicker({
    super.key,
    required this.label,
    required this.expectedKind,
    required this.assets,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final CinematicMediaAssetKind expectedKind;
  final List<CinematicMediaAsset> assets;
  final String? value;
  final ValueChanged<CinematicMediaAsset> onChanged;

  @override
  Widget build(BuildContext context) {
    final compatible = assets
        .where((asset) => asset.kind == expectedKind)
        .toList(growable: false);
    if (compatible.isEmpty) {
      return PokeMapCard(
        key: ValueKey('cinematic-media-picker-empty-${expectedKind.name}'),
        padding: const EdgeInsets.all(10),
        child: Text(
          'Aucun ${_kindLabel(expectedKind)} disponible dans la bibliothèque.',
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final selected = compatible.any((asset) => asset.id == value)
        ? value!
        : compatible.first.id;
    return PokeMapDropdownField<String>(
      key: ValueKey('cinematic-media-picker-${expectedKind.name}'),
      label: label,
      value: selected,
      items: [
        for (final asset in compatible)
          PokeMapDropdownItem(value: asset.id, label: asset.label),
      ],
      onChanged: (id) => onChanged(
        compatible.singleWhere((asset) => asset.id == id),
      ),
    );
  }
}

String _kindLabel(CinematicMediaAssetKind kind) => switch (kind) {
      CinematicMediaAssetKind.sound => 'son',
      CinematicMediaAssetKind.music => 'morceau',
      CinematicMediaAssetKind.cinematicFx => 'effet visuel',
    };
