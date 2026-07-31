import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../application/smart_tile_guide.dart';

/// Human-readable numbered preview of an authoring guide.
class SmartTileGuideDiagram extends StatelessWidget {
  const SmartTileGuideDiagram({
    super.key,
    required this.guide,
    this.compact = false,
  });

  final SmartTileGuideDefinition guide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final minimumColumn = guide.cells
        .map((cell) => cell.deltaColumn)
        .reduce((left, right) => left < right ? left : right);
    final minimumRow = guide.cells
        .map((cell) => cell.deltaRow)
        .reduce((left, right) => left < right ? left : right);
    final extent = compact ? 88.0 : 176.0;

    return Semantics(
      label: '${guide.name}, ${guide.cells.length} cellules numérotées',
      child: SizedBox(
        width: extent,
        height: extent * guide.rows / guide.columns,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / guide.columns;
            final cellHeight = constraints.maxHeight / guide.rows;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(compact ? 6 : 10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Stack(
                children: <Widget>[
                  for (final cell in guide.cells)
                    Positioned(
                      left: (cell.deltaColumn - minimumColumn) * cellWidth,
                      top: (cell.deltaRow - minimumRow) * cellHeight,
                      width: cellWidth,
                      height: cellHeight,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cell.number == 1
                              ? colors.brandPrimary.withValues(alpha: 0.28)
                              : colors.surfaceRaised,
                          border: Border.all(
                            color: cell.number == 1
                                ? colors.brandPrimary
                                : colors.borderStrong,
                          ),
                        ),
                        child: Text(
                          '${cell.number}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: compact ? 9 : 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
