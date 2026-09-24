import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import 'pokemon_ui_parts.dart';

class PokemonMediaPreview extends StatefulWidget {
  const PokemonMediaPreview({
    super.key,
    required this.path,
    required this.controller,
    this.height = 180,
  });

  final String path;
  final PokemonWorkspaceController controller;
  final double height;

  @override
  State<PokemonMediaPreview> createState() => _PokemonMediaPreviewState();
}

class _PokemonMediaPreviewState extends State<PokemonMediaPreview> {
  late Future<Uint8List?> image;

  @override
  void initState() {
    super.initState();
    image = widget.controller.port.loadImage(widget.path);
  }

  @override
  void didUpdateWidget(covariant PokemonMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.controller.port != widget.controller.port) {
      image = widget.controller.port.loadImage(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return SizedBox(
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return PokemonEmptyState(
          title: 'Aperçu indisponible',
          description: 'Fichier absent, illisible ou non pris en charge.',
          icon: Icons.broken_image_outlined,
        );
      }
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const PokemonEmptyState(
            title: 'Image illisible',
            description: 'La référence existe, mais le PNG ne se décode pas.',
            icon: Icons.broken_image_outlined,
          ),
        ),
      );
    },
  );
}
