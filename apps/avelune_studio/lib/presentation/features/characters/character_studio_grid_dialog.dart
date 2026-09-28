import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

Future<(int, int)?> showCharacterStudioGridDialog(
  BuildContext context, {
  required ProjectRegularAtlasTilesetSource source,
  required int tileWidth,
  required int tileHeight,
  required int currentWidth,
  required int currentHeight,
}) {
  final maxWidth = ((source.pixelWidth - source.marginX) ~/ tileWidth).clamp(
    0,
    16,
  );
  final maxHeight = ((source.pixelHeight - source.marginY) ~/ tileHeight).clamp(
    0,
    16,
  );
  var width = currentWidth.clamp(2, maxWidth < 2 ? 2 : maxWidth);
  var height = currentHeight.clamp(2, maxHeight < 2 ? 2 : maxHeight);
  return showDialog<(int, int)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: const Text('Ajuster la grille des poses'),
        content: SizedBox(
          width: 380,
          child: maxWidth < 2 || maxHeight < 2
              ? const Text(
                  'Cette image est trop petite pour une pose de personnage.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choisissez la taille d’une pose dans la grille de la carte. '
                      'Les images déjà placées restent associées à leurs cases.',
                    ),
                    const SizedBox(height: 14),
                    _dimension(
                      'Largeur',
                      width,
                      maxWidth,
                      (value) => update(() => width = value),
                    ),
                    _dimension(
                      'Hauteur',
                      height,
                      maxHeight,
                      (value) => update(() => height = value),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${width * tileWidth} × ${height * tileHeight} px par pose',
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: maxWidth < 2 || maxHeight < 2
                ? null
                : () => Navigator.pop(context, (width, height)),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    ),
  );
}

Widget _dimension(
  String label,
  int selected,
  int maximum,
  ValueChanged<int> onChanged,
) => Row(
  children: [
    Expanded(child: Text(label)),
    DropdownButton<int>(
      value: selected,
      items: [
        for (var value = 2; value <= maximum; value++)
          DropdownMenuItem(value: value, child: Text('$value cases')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  ],
);
