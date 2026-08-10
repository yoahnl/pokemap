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
  static const _minimumZoom = 0.5;
  static const _maximumZoom = 4.0;
  static const _zoomStep = 0.25;

  _PreviewPhase _phase = _PreviewPhase.empty;
  Uint8List? _bytes;
  int _generation = 0;
  double _zoom = 1;

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
      _zoom = 1;
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
        _PreviewPhase.ready => _buildReadyPreview(context),
      },
    );
  }

  Widget _buildReadyPreview(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          bottom: 50,
          child: ClipRect(
            child: Transform.scale(
              scale: _zoom,
              child: Image.memory(
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
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PokeMapPanel(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PokeMapIconButton(
                    key: const ValueKey<String>(
                      'character-studio-preview-zoom-out',
                    ),
                    onPressed: _zoom <= _minimumZoom
                        ? null
                        : () => _setZoom(_zoom - _zoomStep),
                    icon: const Icon(CupertinoIcons.minus),
                    tooltip: 'Réduire le zoom',
                    semanticLabel: 'Réduire le zoom de l’aperçu',
                    size: 28,
                  ),
                  SizedBox(
                    key: const ValueKey<String>(
                      'character-studio-preview-zoom-label',
                    ),
                    width: 58,
                    child: Text(
                      '${(_zoom * 100).round()} %',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PokeMapIconButton(
                    key: const ValueKey<String>(
                      'character-studio-preview-zoom-in',
                    ),
                    onPressed: _zoom >= _maximumZoom
                        ? null
                        : () => _setZoom(_zoom + _zoomStep),
                    icon: const Icon(CupertinoIcons.plus),
                    tooltip: 'Augmenter le zoom',
                    semanticLabel: 'Augmenter le zoom de l’aperçu',
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value.clamp(_minimumZoom, _maximumZoom).toDouble();
    });
  }
}
