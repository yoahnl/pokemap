import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_studio_media_resolver.dart';

class CharacterStudioMediaPreview extends StatefulWidget {
  const CharacterStudioMediaPreview({
    super.key,
    required this.resolver,
    required this.request,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
    this.pixelated = false,
  });

  final CharacterStudioMediaResolverContract resolver;
  final CharacterStudioMediaRequest? request;
  final String semanticLabel;
  final BoxFit fit;
  final bool pixelated;

  @override
  State<CharacterStudioMediaPreview> createState() =>
      _CharacterStudioMediaPreviewState();
}

enum _PreviewPhase { empty, loading, ready, error }

class _CharacterStudioMediaPreviewState
    extends State<CharacterStudioMediaPreview> {
  _PreviewPhase _phase = _PreviewPhase.empty;
  Uint8List? _bytes;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CharacterStudioMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolver != widget.resolver ||
        oldWidget.request != widget.request) {
      _resolve();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _resolve() async {
    final generation = ++_generation;
    final request = widget.request;
    if (request == null) {
      setState(() {
        _phase = _PreviewPhase.empty;
        _bytes = null;
      });
      return;
    }
    setState(() {
      _phase = _PreviewPhase.loading;
      _bytes = null;
    });
    try {
      final bytes = await widget.resolver.resolve(request);
      if (!mounted || generation != _generation) return;
      setState(() {
        _phase = _PreviewPhase.ready;
        _bytes = bytes;
      });
    } on Object {
      if (!mounted || generation != _generation) return;
      setState(() {
        _phase = _PreviewPhase.error;
        _bytes = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapMediaPreviewSurface(
      semanticLabel: widget.semanticLabel,
      child: switch (_phase) {
        _PreviewPhase.empty => const PokeMapEmptyState(
          key: ValueKey<String>('character-studio-preview-empty'),
          title: 'Aucun média',
          description: 'Sélectionnez une image pour afficher son aperçu.',
          icon: Icon(CupertinoIcons.photo),
          compact: true,
        ),
        _PreviewPhase.loading => Center(
          key: const ValueKey<String>('character-studio-preview-loading'),
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.pokeMapColors.brandPrimary,
            ),
          ),
        ),
        _PreviewPhase.error => const PokeMapEmptyState(
          key: ValueKey<String>('character-studio-preview-error'),
          title: 'Aperçu indisponible',
          description: 'Le média est absent ou illisible.',
          icon: Icon(CupertinoIcons.exclamationmark_triangle),
          compact: true,
        ),
        _PreviewPhase.ready => Image.memory(
          _bytes!,
          key: const ValueKey<String>('character-studio-preview-content'),
          fit: widget.fit,
          filterQuality: widget.pixelated
              ? FilterQuality.none
              : FilterQuality.medium,
          gaplessPlayback: false,
          errorBuilder: (context, error, stackTrace) {
            return const PokeMapEmptyState(
              key: ValueKey<String>('character-studio-preview-error'),
              title: 'Aperçu indisponible',
              description: 'Le média est absent ou illisible.',
              icon: Icon(CupertinoIcons.exclamationmark_triangle),
              compact: true,
            );
          },
        ),
      },
    );
  }
}
