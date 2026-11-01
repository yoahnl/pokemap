import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'battle_spl_point_preview_painter.dart';
import 'battle_spl_static_admission.dart';

final class BattleSplStaticComponent extends PositionComponent {
  BattleSplStaticComponent({
    required this.playback,
    required Map<int, ui.Image> textures,
    required this.origin,
    required this.pixelsPerUnit,
    required this.onComplete,
    required this.onFailure,
    this.maxTicksPerUpdate = 16,
  }) {
    if (textures.length != playback.textureIndices.length ||
        !textures.keys.toSet().containsAll(playback.textureIndices) ||
        !origin.dx.isFinite ||
        !origin.dy.isFinite ||
        !pixelsPerUnit.isFinite ||
        pixelsPerUnit <= 0 ||
        pixelsPerUnit > 4096 ||
        maxTicksPerUpdate < 1 ||
        maxTicksPerUpdate > 256) {
      throw const FormatException('Invalid static SPL component');
    }
    var pixels = 0;
    for (final image in textures.values) {
      if (image.width < 1 ||
          image.height < 1 ||
          image.width > 2048 ||
          image.height > 2048 ||
          image.width * image.height > 4000000) {
        throw const FormatException('Invalid SPL texture dimensions');
      }
      pixels += image.width * image.height;
      if (pixels > 16000000) {
        throw const FormatException('SPL texture budget exceeded');
      }
    }
    try {
      for (final entry in textures.entries) {
        _textures[entry.key] = entry.value.clone();
      }
      for (final frame in playback.frames) {
        _painters.add(
          BattleSplPointPreviewPainter(
            textures: _textures,
            pixelsPerUnit: pixelsPerUnit,
            aspectRatio4096: frame.aspectRatio4096,
            directionalParents: frame.directional,
            scaleAxis: switch (frame.scaleAxis) {
              'x' => BattleSplPreviewScaleAxis.x,
              'y' => BattleSplPreviewScaleAxis.y,
              'xy' => BattleSplPreviewScaleAxis.xy,
              _ => throw const FormatException('Invalid SPL scale axis'),
            },
          ),
        );
      }
    } catch (_) {
      for (final image in _textures.values) {
        image.dispose();
      }
      _textures.clear();
      rethrow;
    }
  }

  final BattleSplStaticPlayback playback;
  final ui.Offset origin;
  final double pixelsPerUnit;
  final void Function() onComplete;
  final void Function(BattleSplAdmissionFailure) onFailure;
  final int maxTicksPerUpdate;
  final Map<int, ui.Image> _textures = {};
  final List<BattleSplPointPreviewPainter> _painters = [];
  double _pendingTicks = 0;
  bool _disposed = false;
  bool _notified = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_disposed || _notified || !dt.isFinite || dt < 0) return;
    final elapsedTicks = dt >= playback.maxTicks / 60
        ? playback.maxTicks.toDouble()
        : dt * 60;
    _pendingTicks = math.min(
      _pendingTicks + elapsedTicks,
      (playback.maxTicks - playback.tick).toDouble(),
    );
    var work = 0;
    while (_pendingTicks + 0.000000001 >= 1 &&
        work < maxTicksPerUpdate &&
        !playback.isComplete) {
      _pendingTicks = math.max(0, _pendingTicks - 1);
      final failure = playback.advance();
      if (failure != null) {
        _notified = true;
        dispose();
        onFailure(failure);
        return;
      }
      work++;
    }
    if (playback.isComplete && !_notified) {
      _notified = true;
      dispose();
      onComplete();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_disposed) return;
    final frames = playback.frames;
    for (var i = 0; i < frames.length; i++) {
      _painters[i].paint(
        canvas,
        origin: origin,
        particles: frames[i].particles,
      );
    }
  }

  void cancel() => dispose();

  void dispose() => _dispose(remove: true);

  void _dispose({required bool remove}) {
    if (_disposed) return;
    _disposed = true;
    playback.cancel();
    for (final image in _textures.values) {
      image.dispose();
    }
    _textures.clear();
    if (remove) removeFromParent();
  }

  @override
  void onRemove() {
    _dispose(remove: false);
    super.onRemove();
  }
}
