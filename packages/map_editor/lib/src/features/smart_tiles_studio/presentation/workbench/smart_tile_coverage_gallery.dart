import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_form_projection.dart';

class SmartTileCoverageGallery extends StatelessWidget {
  const SmartTileCoverageGallery({
    super.key,
    required this.forms,
    required this.topology,
    required this.selectedMask,
    required this.onSelected,
  });

  final List<SmartTileFormReadModel> forms;
  final SmartTileTopology topology;
  final int? selectedMask;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (forms.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune forme projetable',
        description: 'Choisissez d’abord une structure de raccord.',
        icon: Icon(CupertinoIcons.square_grid_3x2),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 560
            ? constraints.maxWidth
            : constraints.maxWidth < 900
                ? (constraints.maxWidth - 8) / 2
                : (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final form in forms)
              SizedBox(
                width: cardWidth,
                child: PokeMapAssetCard(
                  key: Key('smart-tiles-form-${form.mask}'),
                  thumbnail: SmartTileFormGlyph(
                    mask: form.mask,
                    topology: topology,
                  ),
                  label: form.label,
                  description: form.description,
                  selected: selectedMask == form.mask,
                  onPressed: () => onSelected(form.mask),
                  trailing: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: <Widget>[
                      PokeMapBadge(
                        label: _statusLabel(form.status),
                        variant: _statusVariant(form.status),
                      ),
                      if (form.variantCount > 0)
                        PokeMapBadge(
                          label: '${form.variantCount} variante(s)',
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SmartTileFormGlyph extends StatelessWidget {
  const SmartTileFormGlyph({
    super.key,
    required this.mask,
    required this.topology,
    this.dimension = 38,
  });

  final int mask;
  final SmartTileTopology topology;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      label: 'Pictogramme de raccord',
      image: true,
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(
          painter: _SmartTileFormGlyphPainter(
            mask: mask,
            topology: topology,
            activeColor: colors.mapAccent,
            inactiveColor: colors.surfaceSubtle,
            borderColor: colors.borderSubtle,
          ),
        ),
      ),
    );
  }
}

final class _SmartTileFormGlyphPainter extends CustomPainter {
  const _SmartTileFormGlyphPainter({
    required this.mask,
    required this.topology,
    required this.activeColor,
    required this.inactiveColor,
    required this.borderColor,
  });

  final int mask;
  final SmartTileTopology topology;
  final Color activeColor;
  final Color inactiveColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    final fill = Paint()..color = inactiveColor;
    final active = Paint()..color = activeColor;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 3; row += 1) {
      for (var column = 0; column < 3; column += 1) {
        final rect = Rect.fromLTWH(column * cell, row * cell, cell, cell);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);
      }
    }
    canvas.drawRect(Rect.fromLTWH(cell, cell, cell, cell), active);
    for (final neighbor in _activeNeighborCells(mask, topology)) {
      canvas.drawRect(
        Rect.fromLTWH(neighbor.$1 * cell, neighbor.$2 * cell, cell, cell),
        active,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmartTileFormGlyphPainter oldDelegate) =>
      oldDelegate.mask != mask ||
      oldDelegate.topology != topology ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor ||
      oldDelegate.borderColor != borderColor;
}

List<(int, int)> _activeNeighborCells(
  int mask,
  SmartTileTopology topology,
) =>
    <(int, int)>[
      if (mask & smartTileNorthBit != 0) (1, 0),
      if (mask & smartTileEastBit != 0) (2, 1),
      if (mask & smartTileSouthBit != 0) (1, 2),
      if (mask & smartTileWestBit != 0) (0, 1),
      if (mask & smartTileNorthWestBit != 0) (0, 0),
      if (mask & smartTileNorthEastBit != 0) (2, 0),
      if (mask & smartTileSouthEastBit != 0) (2, 2),
      if (mask & smartTileSouthWestBit != 0) (0, 2),
    ];

String _statusLabel(SmartTileVisibleFormStatus status) => switch (status) {
      SmartTileVisibleFormStatus.covered => 'Couvert',
      SmartTileVisibleFormStatus.generated => 'Généré',
      SmartTileVisibleFormStatus.fallback => 'Secours',
      SmartTileVisibleFormStatus.ambiguous => 'Ambigu',
      SmartTileVisibleFormStatus.missing => 'Manquant',
    };

PokeMapBadgeVariant _statusVariant(SmartTileVisibleFormStatus status) =>
    switch (status) {
      SmartTileVisibleFormStatus.covered => PokeMapBadgeVariant.success,
      SmartTileVisibleFormStatus.generated => PokeMapBadgeVariant.info,
      SmartTileVisibleFormStatus.fallback => PokeMapBadgeVariant.warning,
      SmartTileVisibleFormStatus.ambiguous => PokeMapBadgeVariant.error,
      SmartTileVisibleFormStatus.missing => PokeMapBadgeVariant.warning,
    };
