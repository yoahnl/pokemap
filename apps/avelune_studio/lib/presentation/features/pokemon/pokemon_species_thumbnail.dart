import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../../features/pokemon/domain/pokemon_workspace_port.dart';

class PokemonSpeciesThumbnail extends StatefulWidget {
  const PokemonSpeciesThumbnail({
    super.key,
    required this.entry,
    required this.port,
    this.size = 48,
  });

  final PokemonSpeciesSummary entry;
  final PokemonWorkspacePort port;
  final double size;

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
    width: widget.size,
    height: widget.size,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                snapshot.connectionState == ConnectionState.waiting
                    ? Icons.hourglass_empty
                    : Icons.image_not_supported_outlined,
                size: widget.size > 64 ? 30 : 18,
              ),
              if (widget.size > 64 &&
                  MediaQuery.textScalerOf(context).scale(12) < 18) ...[
                const SizedBox(height: 8),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? 'Chargement…'
                      : 'Aucun aperçu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
