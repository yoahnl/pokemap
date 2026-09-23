import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../features/narrative/domain/narrative_port.dart';

class NarrativeArtworkImage extends StatefulWidget {
  const NarrativeArtworkImage({
    super.key,
    required this.port,
    required this.kind,
    required this.fallback,
    this.id,
    this.fit = BoxFit.cover,
  });

  final NarrativeArtworkPort? port;
  final NarrativeArtworkKind kind;
  final String? id;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<NarrativeArtworkImage> createState() => _NarrativeArtworkImageState();
}

class _NarrativeArtworkImageState extends State<NarrativeArtworkImage> {
  Future<Uint8List?>? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NarrativeArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.port != widget.port ||
        oldWidget.kind != widget.kind ||
        oldWidget.id != widget.id) {
      _load();
    }
  }

  void _load() {
    _image = widget.port?.readArtwork(widget.kind, id: widget.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.fallback;
      }
      final bytes = snapshot.data;
      if (bytes == null) return widget.fallback;
      return Image.memory(
        bytes,
        fit: widget.fit,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    },
  );
}
