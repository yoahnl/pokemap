import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'battle_live_attachment.dart';
import 'battle_spl_camera_projection.dart';
import 'battle_spl_point_emitter_playback.dart';
import 'battle_spl_point_preview_painter.dart';
import 'battle_spl_static_admission.dart';

final class BattleSplStaticComponent extends PositionComponent
    implements BattleLiveAttachment {
  BattleSplStaticComponent({
    required this.playback,
    required Map<int, ui.Image> textures,
    required this.origin,
    required this.pixelsPerUnit,
    required this.onComplete,
    required this.onFailure,
    this.projection,
    List<BattleSplWorldAnchor>? initialAnchors,
    this.maxTicksPerUpdate = 16,
  }) {
    final frames = playback.frames;
    if (textures.length != playback.textureIndices.length ||
        !textures.keys.toSet().containsAll(playback.textureIndices) ||
        !origin.dx.isFinite ||
        !origin.dy.isFinite ||
        !pixelsPerUnit.isFinite ||
        pixelsPerUnit <= 0 ||
        pixelsPerUnit > 4096 ||
        maxTicksPerUpdate < 1 ||
        maxTicksPerUpdate > 256 ||
        (projection == null && initialAnchors != null) ||
        (projection != null && projection!.bindings.length != frames.length)) {
      throw const FormatException('Invalid static SPL component');
    }
    if (projection != null) {
      final anchors = initialAnchors ?? projection!.capture();
      if (anchors == null ||
          anchors.length != frames.length ||
          anchors.any((anchor) => projection!.project(anchor) == null)) {
        throw const FormatException('SPL projection unavailable');
      }
      _anchors = List.unmodifiable(anchors);
      _snapshots = [for (final _ in frames) <int, BattleSplWorldAnchor>{}];
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
      for (final frame in frames) {
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
  final BattleSplCameraProjection? projection;
  final int maxTicksPerUpdate;
  final Map<int, ui.Image> _textures = {};
  final List<BattleSplPointPreviewPainter> _painters = [];
  List<BattleSplWorldAnchor> _anchors = const [];
  List<Map<int, BattleSplWorldAnchor>> _snapshots = const [];
  double _pendingTicks = 0;
  bool _disposed = false;
  bool _notified = false;

  @override
  bool refreshAttachment() {
    if (_disposed) return false;
    final activeProjection = projection;
    if (activeProjection == null) return true;
    final anchors = activeProjection.capture();
    if (anchors == null ||
        anchors.length != _painters.length ||
        _snapshots.any(
          (frame) => frame.values.any(
            (anchor) => activeProjection.project(anchor) == null,
          ),
        )) {
      _fail(BattleSplAdmissionFailure.projectionUnavailable);
      return false;
    }
    _anchors = anchors;
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_disposed || _notified || !dt.isFinite || dt < 0) return;
    if (!refreshAttachment()) return;
    final elapsedTicks = dt >= playback.maxTicks / 60
        ? playback.maxTicks.toDouble()
        : dt * 60;
    _pendingTicks = math.min(
      _pendingTicks + elapsedTicks,
      (playback.maxTicks - playback.tick).toDouble(),
    );
    if (projection != null &&
        (elapsedTicks > 1.000000001 || _pendingTicks + 0.000000001 >= 2)) {
      _fail(BattleSplAdmissionFailure.projectionUnavailable);
      return;
    }
    var work = 0;
    while (_pendingTicks + 0.000000001 >= 1 &&
        work < maxTicksPerUpdate &&
        !playback.isComplete) {
      _pendingTicks = math.max(0, _pendingTicks - 1);
      final failure = playback.advance();
      if (failure != null) {
        _fail(failure);
        return;
      }
      if (projection != null && !_captureSnapshots()) {
        _fail(BattleSplAdmissionFailure.projectionUnavailable);
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
    final activeProjection = projection;
    if (activeProjection != null) {
      final groups =
          <
            ({
              int frame,
              BattleSplWorldAnchor neutral,
              BattleSplProjectedAnchor projected,
              List<BattleSplPointParticle> particles,
            })
          >[];
      final projectedAnchors =
          <BattleSplWorldAnchor, BattleSplProjectedAnchor>{};
      for (var i = 0; i < frames.length; i++) {
        final frame = frames[i];
        for (final particle in frame.particles) {
          final follows = particle.parentId == null
              ? frame.followEmitter
              : frame.childFollowsEmitter;
          final anchor = follows ? _anchors[i] : _snapshots[i][particle.id];
          if (anchor == null) {
            _fail(BattleSplAdmissionFailure.projectionUnavailable);
            return;
          }
          final projected =
              projectedAnchors[anchor] ?? activeProjection.project(anchor);
          if (projected == null) {
            _fail(BattleSplAdmissionFailure.projectionUnavailable);
            return;
          }
          projectedAnchors[anchor] = projected;
          if (groups.isNotEmpty &&
              groups.last.frame == i &&
              groups.last.neutral == anchor) {
            groups.last.particles.add(particle);
          } else {
            groups.add((
              frame: i,
              neutral: anchor,
              projected: projected,
              particles: [particle],
            ));
          }
        }
      }
      for (final group in groups) {
        canvas.save();
        try {
          canvas.translate(
            group.projected.anchor.dx,
            group.projected.anchor.dy,
          );
          canvas.scale(group.projected.scale);
          _painters[group.frame].paint(
            canvas,
            origin: origin,
            particles: group.particles,
          );
        } finally {
          canvas.restore();
        }
      }
      return;
    }
    for (var i = 0; i < frames.length; i++) {
      _painters[i].paint(
        canvas,
        origin: origin,
        particles: frames[i].particles,
      );
    }
  }

  bool _captureSnapshots() {
    final frames = playback.frames;
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final previous = _snapshots[i];
      final next = <int, BattleSplWorldAnchor>{};
      for (final particle in frame.particles) {
        if (particle.parentId == null && !frame.followEmitter) {
          next[particle.id] = previous[particle.id] ?? _anchors[i];
        }
      }
      for (final particle in frame.particles) {
        final parentId = particle.parentId;
        if (parentId == null || frame.childFollowsEmitter) continue;
        final anchor =
            previous[particle.id] ??
            (frame.followEmitter
                ? _anchors[i]
                : next[parentId] ?? previous[parentId]);
        if (anchor == null) return false;
        next[particle.id] = anchor;
      }
      _snapshots[i] = next;
    }
    return true;
  }

  void _fail(BattleSplAdmissionFailure failure) {
    if (_notified || _disposed) return;
    _notified = true;
    dispose();
    onFailure(failure);
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
    _anchors = const [];
    _snapshots = const [];
    if (remove) removeFromParent();
  }

  @override
  void onRemove() {
    _dispose(remove: false);
    super.onRemove();
  }
}
