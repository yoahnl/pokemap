import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_ui_parts.dart';

class PokemonCaptureSpritePicker extends StatefulWidget {
  const PokemonCaptureSpritePicker({
    super.key,
    required this.commerce,
    this.pickPng,
  });

  final PokemonCommerceController commerce;
  final Future<String?> Function()? pickPng;

  @override
  State<PokemonCaptureSpritePicker> createState() =>
      _PokemonCaptureSpritePickerState();
}

class _PokemonCaptureSpritePickerState
    extends State<PokemonCaptureSpritePicker> {
  bool choosing = false;

  Future<void> _choose() async {
    final item = widget.commerce.item;
    setState(() => choosing = true);
    try {
      final source = await widget.pickPng!();
      if (!mounted ||
          source == null ||
          !identical(item, widget.commerce.item)) {
        return;
      }
      await widget.commerce.importCaptureSprite(sourcePath: source);
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commerce = widget.commerce;
    final capture = commerce.item!.capture!;
    final path = capture.animationSpritePath;
    final busy = choosing || commerce.importing || commerce.saving;
    return PokemonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PokemonSectionHeading(
            title: 'Animation de capture',
            description:
                'Planche PNG de 64 × 2048 pixels : 32 images de 64 × 64.',
          ),
          if (path == null)
            const Text('Aucune animation choisie.')
          else ...[
            _CapturePreview(
              key: ValueKey(path),
              commerce: commerce,
              path: path,
            ),
            const SizedBox(height: 8),
            const Text('Animation personnalisée associée à cet objet.'),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                label: busy ? 'Import en cours…' : 'Choisir une planche PNG',
                icon: Icons.file_upload_outlined,
                onPressed: busy || widget.pickPng == null ? null : _choose,
              ),
              if (path != null)
                StudioButton(
                  label: 'Retirer l’animation',
                  secondary: true,
                  onPressed: busy
                      ? null
                      : () => commerce.editItem(
                          (item) => item.copyWith(
                            capture: item.capture!.copyWith(
                              animationSpritePath: null,
                            ),
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le choix reste dans le brouillon jusqu’à Enregistrer. Une annulation conserve la planche importée dans le projet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CapturePreview extends StatefulWidget {
  const _CapturePreview({
    super.key,
    required this.commerce,
    required this.path,
  });

  final PokemonCommerceController commerce;
  final String path;

  @override
  State<_CapturePreview> createState() => _CapturePreviewState();
}

class _CapturePreviewState extends State<_CapturePreview> {
  late final image = widget.commerce.port.loadCaptureSprite(widget.path);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          width: 64,
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.data == null) return const Text('Aperçu indisponible.');
      return SizedBox(
        width: 64,
        height: 64,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 2048,
            maxHeight: 2048,
            child: Image.memory(
              snapshot.data!,
              width: 64,
              height: 2048,
              filterQuality: FilterQuality.none,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('PNG illisible.'),
            ),
          ),
        ),
      );
    },
  );
}
