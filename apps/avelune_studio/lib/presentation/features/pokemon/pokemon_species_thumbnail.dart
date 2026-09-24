import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../../features/pokemon/domain/pokemon_workspace_port.dart';

class PokemonSpeciesThumbnail extends StatefulWidget {
  const PokemonSpeciesThumbnail({
    super.key,
    required this.entry,
    required this.port,
  });

  final PokemonSpeciesSummary entry;
  final PokemonWorkspacePort port;

  @override
  State<PokemonSpeciesThumbnail> createState() =>
      _PokemonSpeciesThumbnailState();
}

class _PokemonSpeciesThumbnailState extends State<PokemonSpeciesThumbnail> {
  late Future<Uint8List?> image = widget.port.loadThumbnail(widget.entry);

  @override
  void didUpdateWidget(PokemonSpeciesThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry || oldWidget.port != widget.port) {
      image = widget.port.loadThumbnail(widget.entry);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: FutureBuilder<Uint8List?>(
      future: image,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        }
        return Tooltip(
          message: snapshot.hasError
              ? 'Aperçu indisponible : ${snapshot.error}'
              : 'Aucune image locale disponible',
          child: Icon(
            snapshot.connectionState == ConnectionState.waiting
                ? Icons.hourglass_empty
                : Icons.image_not_supported_outlined,
          ),
        );
      },
    ),
  );
}
