import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';

class PickedResourceImage {
  const PickedResourceImage(
    this.path,
    this.name,
    this.bytes,
    this.width,
    this.height,
  );
  final String path;
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
}

typedef PickResourceImage = Future<PickedResourceImage?> Function();

Future<ResourceImageImport?> confirmImageImport(
  BuildContext context,
  PickedResourceImage image,
  int tileWidth,
  int tileHeight,
) async {
  final name = TextEditingController(text: image.name);
  final width = TextEditingController(text: '$tileWidth');
  final height = TextEditingController(text: '$tileHeight');
  final result = await showDialog<ResourceImageImport>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, rebuild) {
        final w = int.tryParse(width.text) ?? 0;
        final h = int.tryParse(height.text) ?? 0;
        final valid =
            name.text.trim().isNotEmpty &&
            w > 0 &&
            h > 0 &&
            w <= image.width &&
            h <= image.height;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importer une image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Image.memory(
                      image.bytes,
                      cacheWidth: 600,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, _, _) => const StudioNotice(
                        'Cette image PNG ne peut pas être prévisualisée.',
                        isError: true,
                      ),
                    ),
                  ),
                  Text(
                    '${image.width} × ${image.height} px · PNG · copie sans redimensionnement',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    onChanged: (_) => rebuild(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: width,
                          decoration: const InputDecoration(
                            labelText: 'Largeur de cellule (px)',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => rebuild(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: height,
                          decoration: const InputDecoration(
                            labelText: 'Hauteur de cellule (px)',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => rebuild(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StudioNotice(
                    'Une nouvelle ressource sera copiée dans le projet. Aucun fichier existant ne sera remplacé.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StudioButton(
                        label: 'Annuler',
                        secondary: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                      StudioButton(
                        label: 'Importer',
                        onPressed: valid
                            ? () => Navigator.pop(
                                context,
                                ResourceImageImport(
                                  sourcePath: image.path,
                                  name: name.text.trim(),
                                  tileWidth: w,
                                  tileHeight: h,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  name.dispose();
  width.dispose();
  height.dispose();
  return result;
}
