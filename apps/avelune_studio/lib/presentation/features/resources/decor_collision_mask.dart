import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class DecorCollisionMask extends StatelessWidget {
  const DecorCollisionMask({
    super.key,
    required this.width,
    required this.height,
    required this.blocked,
    required this.onToggle,
  });
  final int width;
  final int height;
  final Set<GridPos> blocked;
  final ValueChanged<GridPos> onToggle;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maximumWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 200.0;
        final gap = math.min(
          2.0,
          math.min(maximumWidth / width, 200 / height) * .1,
        );
        final cell = math.min(
          36.0,
          math.min(
            (maximumWidth - (width - 1) * gap) / width,
            (200 - (height - 1) * gap) / height,
          ),
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width * cell + (width - 1) * gap,
            height: height * cell + (height - 1) * gap,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
              ),
              itemCount: width * height,
              itemBuilder: (context, index) {
                final point = GridPos(x: index % width, y: index ~/ width);
                final solid = blocked.contains(point);
                return Semantics(
                  button: true,
                  label:
                      'Case ${point.x + 1}, ${point.y + 1} · ${solid ? 'bloquée' : 'traversable'}',
                  child: InkWell(
                    key: ValueKey('collision-${point.x}-${point.y}'),
                    onTap: () => onToggle(point),
                    child: ColoredBox(
                      color: solid
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Icon(
                        solid ? Icons.block : Icons.check,
                        size: math.min(14, cell * .6),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
