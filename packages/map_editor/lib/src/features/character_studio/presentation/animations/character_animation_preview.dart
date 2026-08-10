import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_playback_controller.dart';

enum CharacterAnimationPreviewBackground { checker, light, dark }

class CharacterAnimationPreview extends StatefulWidget {
  const CharacterAnimationPreview({
    super.key,
    required this.sourceBytes,
    required this.frames,
    required this.loop,
    required this.slotIdentity,
    required this.directionLabel,
    required this.enabled,
    required this.onLoopChanged,
  });

  final Uint8List sourceBytes;
  final List<CharacterAnimationFrame> frames;
  final bool loop;
  final String slotIdentity;
  final String directionLabel;
  final bool enabled;
  final Future<void> Function(bool loop) onLoopChanged;

  @override
  State<CharacterAnimationPreview> createState() =>
      _CharacterAnimationPreviewState();
}

class _CharacterAnimationPreviewState extends State<CharacterAnimationPreview>
    with SingleTickerProviderStateMixin {
  late final CharacterAnimationPlaybackController _playback;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Future<ui.Image>? _image;
  int? _sourceFingerprint;
  double _zoom = 2;
  CharacterAnimationPreviewBackground _background =
      CharacterAnimationPreviewBackground.checker;

  @override
  void initState() {
    super.initState();
    _playback = CharacterAnimationPlaybackController(
      frames: widget.frames,
      loop: widget.loop,
    );
    _ticker = createTicker(_tick);
    _refreshImage();
  }

  @override
  void didUpdateWidget(covariant CharacterAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slotIdentity != widget.slotIdentity ||
        !_sameFrames(oldWidget.frames, widget.frames)) {
      _stopTicker();
      _playback.replaceFrames(widget.frames);
    }
    _playback.loop = widget.loop;
    if (!widget.enabled && _playback.isPlaying) {
      _pause();
    }
    _refreshImage();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey<String>('animation-preview'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aperçu live',
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PokeMapBadge(
                label: widget.directionLabel,
                variant: PokeMapBadgeVariant.info,
              ),
              const SizedBox(width: 6),
              PokeMapIconButton(
                key: const ValueKey<String>('animation-preview-loop'),
                onPressed: widget.enabled
                    ? () => widget.onLoopChanged(!widget.loop)
                    : null,
                icon: const Icon(Icons.repeat_rounded),
                tooltip: widget.loop ? 'Boucle activée' : 'Boucle désactivée',
                isSelected: widget.loop,
                variant: PokeMapIconButtonVariant.soft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 170, child: _previewSurface(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PokeMapIconButton(
                key: const ValueKey<String>('animation-preview-previous'),
                onPressed: widget.enabled && widget.frames.isNotEmpty
                    ? _stepPrevious
                    : null,
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: 'Frame précédente',
                variant: PokeMapIconButtonVariant.soft,
              ),
              PokeMapIconButton(
                key: const ValueKey<String>('animation-preview-play-pause'),
                onPressed: widget.enabled && widget.frames.isNotEmpty
                    ? _togglePlayback
                    : null,
                icon: Icon(
                  _playback.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                tooltip: _playback.isPlaying ? 'Pause' : 'Lecture',
                variant: PokeMapIconButtonVariant.soft,
                isSelected: _playback.isPlaying,
              ),
              PokeMapIconButton(
                key: const ValueKey<String>('animation-preview-next'),
                onPressed: widget.enabled && widget.frames.isNotEmpty
                    ? _stepNext
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Frame suivante',
                variant: PokeMapIconButtonVariant.soft,
              ),
              const SizedBox(width: 4),
              for (final speed in const <double>[0.5, 1, 2])
                PokeMapButton(
                  key: ValueKey<String>(
                    'animation-preview-speed-${_numberKey(speed)}',
                  ),
                  onPressed: () => setState(() => _playback.speed = speed),
                  variant: _playback.speed == speed
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: Text('${_numberLabel(speed)}×'),
                ),
              const SizedBox(width: 4),
              for (final zoom in const <double>[1, 2, 4])
                PokeMapButton(
                  key: ValueKey<String>(
                    'animation-preview-zoom-${_numberKey(zoom)}',
                  ),
                  onPressed: () => setState(() => _zoom = zoom),
                  variant: _zoom == zoom
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: Text('Zoom ${_numberLabel(zoom)}×'),
                ),
              PokeMapIconButton(
                key: const ValueKey<String>('animation-preview-background'),
                onPressed: _cycleBackground,
                icon: const Icon(Icons.grid_4x4_rounded),
                tooltip: 'Changer le fond',
                variant: PokeMapIconButtonVariant.soft,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewSurface(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune frame à lire',
        description: 'Appliquez une grille ou ajoutez une frame.',
        icon: Icon(Icons.animation_rounded),
        compact: true,
      );
    }
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final image = snapshot.data;
        if (snapshot.hasError || image == null) {
          return PokeMapEmptyState(
            title: 'Aperçu indisponible',
            description:
                '${snapshot.error ?? 'Le PNG ne peut pas être décodé.'}',
            icon: const Icon(Icons.broken_image_outlined),
            compact: true,
          );
        }
        final frame = widget.frames[_playback.currentFrameIndex];
        final source = frame.source;
        if (source.x < 0 ||
            source.y < 0 ||
            source.width <= 0 ||
            source.height <= 0 ||
            source.x + source.width > image.width ||
            source.y + source.height > image.height) {
          return const PokeMapEmptyState(
            title: 'Frame hors de la source',
            description: 'Corrigez le rectangle sélectionné avant la lecture.',
            icon: Icon(Icons.crop_free_rounded),
            compact: true,
          );
        }
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _backgroundColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.pokeMapColors.borderSubtle),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: KeyedSubtree(
                key: ValueKey<String>(
                  'animation-preview-frame-${_playback.currentFrameIndex}',
                ),
                child: CustomPaint(
                  size: Size(source.width * _zoom, source.height * _zoom),
                  painter: _AnimationFramePainter(image: image, source: source),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _backgroundColor(BuildContext context) {
    return switch (_background) {
      CharacterAnimationPreviewBackground.checker =>
        context.pokeMapColors.surfaceSubtle,
      CharacterAnimationPreviewBackground.light =>
        context.pokeMapColors.contentSurface,
      CharacterAnimationPreviewBackground.dark =>
        context.pokeMapColors.backgroundShell,
    };
  }

  void _togglePlayback() {
    if (_playback.isPlaying) {
      _pause();
      return;
    }
    _playback.play();
    _lastTick = Duration.zero;
    _ticker.start();
    setState(() {});
  }

  void _pause() {
    _playback.pause();
    _stopTicker();
    setState(() {});
  }

  void _stepPrevious() {
    _stopTicker();
    setState(_playback.stepPrevious);
  }

  void _stepNext() {
    _stopTicker();
    setState(_playback.stepNext);
  }

  void _tick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    _playback.advance(delta);
    if (!_playback.isPlaying) _stopTicker();
    if (mounted) setState(() {});
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop(canceled: false);
    _lastTick = Duration.zero;
  }

  void _cycleBackground() {
    setState(() {
      _background =
          CharacterAnimationPreviewBackground.values[(_background.index + 1) %
              CharacterAnimationPreviewBackground.values.length];
    });
  }

  void _refreshImage() {
    final fingerprint = Object.hashAll(widget.sourceBytes);
    if (fingerprint == _sourceFingerprint) return;
    _sourceFingerprint = fingerprint;
    _image = _decodeImage(widget.sourceBytes);
  }
}

final class _AnimationFramePainter extends CustomPainter {
  const _AnimationFramePainter({required this.image, required this.source});

  final ui.Image image;
  final TilesetSourceRect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        source.x.toDouble(),
        source.y.toDouble(),
        source.width.toDouble(),
        source.height.toDouble(),
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimationFramePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.source != source;
  }
}

Future<ui.Image> _decodeImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

bool _sameFrames(
  List<CharacterAnimationFrame> left,
  List<CharacterAnimationFrame> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _numberKey(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String _numberLabel(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
