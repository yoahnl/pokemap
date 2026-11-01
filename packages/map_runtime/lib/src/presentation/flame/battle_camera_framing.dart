import 'dart:math' as math;
import 'dart:ui';

import 'battle_camera_subject_geometry.dart';
import 'battle_perspective_camera.dart';

export 'battle_camera_subject_geometry.dart';

enum BattleCameraShotIntent { overview, attacker, target, group }

enum BattleCameraReframePolicy { fitRequired, holdPose }

enum BattleCameraFramingDiagnostic {
  ideal,
  reframed,
  transitionStartsOccluded,
  trajectoryBlocked,
  noSpace,
  invalidGeometry,
}

typedef BattleCameraPose = ({BattleCameraPoint eye, BattleCameraPoint aim});
typedef BattleCameraSubjectProjection = ({String id, Rect bounds});

final class BattleCameraSubject {
  const BattleCameraSubject({required this.id, required this.geometry});
  final String id;
  final BattleCameraSubjectGeometry geometry;
}

final class BattleCameraShot {
  const BattleCameraShot({
    required this.eye,
    required this.aim,
    required this.startPose,
    required this.projections,
    required this.fits,
    required this.trajectoryFits,
    required this.diagnostic,
  });
  final BattleCameraPoint eye;
  final BattleCameraPoint aim;
  final BattleCameraPose startPose;
  final List<BattleCameraSubjectProjection> projections;
  final bool fits;
  final bool trajectoryFits;
  final BattleCameraFramingDiagnostic diagnostic;
}

final class BattleCameraShotResolver {
  const BattleCameraShotResolver();

  BattleCameraShot resolve({
    required BattlePerspectiveCamera camera,
    required BattleCameraShotIntent intent,
    required List<BattleCameraSubject> subjects,
    required Rect usefulViewport,
    required List<Rect> obstacles,
    String? principalId,
    Set<String> groupIds = const {},
    bool playerSide = false,
    double strength = 1,
    double margin = 8,
    BattleCameraReframePolicy policy = BattleCameraReframePolicy.fitRequired,
  }) {
    final start = (eye: camera.eye, aim: camera.aim);
    final required = subjects
        .where(
          (subject) => switch (intent) {
            BattleCameraShotIntent.overview => true,
            BattleCameraShotIntent.group => groupIds.contains(subject.id),
            _ => subject.id == principalId,
          },
        )
        .toList(growable: false);
    BattleCameraShot failure(BattleCameraFramingDiagnostic diagnostic) =>
        BattleCameraShot(
          eye: start.eye,
          aim: start.aim,
          startPose: start,
          projections: const [],
          fits: false,
          trajectoryFits: false,
          diagnostic: diagnostic,
        );
    final probe = BattlePerspectiveCamera(viewport: camera.viewport);
    if (required.isEmpty ||
        required.any(
          (subject) =>
              !subject.geometry.isValid ||
              probe.tryBillboardAt(subject.geometry.foot) == null,
        ) ||
        !strength.isFinite ||
        strength < 0 ||
        strength > 1 ||
        !margin.isFinite ||
        margin < 0 ||
        !_validRect(usefulViewport) ||
        obstacles.any((rect) => !_finiteRect(rect))) {
      return failure(BattleCameraFramingDiagnostic.invalidGeometry);
    }
    final region = usefulViewport.intersect(camera.viewport).deflate(margin);
    if (region.isEmpty) return failure(BattleCameraFramingDiagnostic.noSpace);
    final blocked = obstacles
        .where((rect) => !rect.isEmpty)
        .map((rect) => rect.inflate(margin))
        .toList();
    List<BattleCameraSubjectProjection>? project(BattleCameraPose pose) {
      try {
        probe.moveTo(eye: pose.eye, aim: pose.aim, durationSeconds: 0);
      } on ArgumentError {
        return null;
      }
      final result = <BattleCameraSubjectProjection>[];
      for (final subject in required) {
        final projected = probe.tryBillboardAt(subject.geometry.foot);
        if (projected == null ||
            !projected.scale.isFinite ||
            projected.scale <= 0) {
          return null;
        }
        final rect = subject.geometry.framingBounds;
        final offset = rect.topLeft - subject.geometry.foot;
        final bounds = Rect.fromLTWH(
          projected.position.dx + offset.dx * projected.scale,
          projected.position.dy + offset.dy * projected.scale,
          rect.width * projected.scale,
          rect.height * projected.scale,
        );
        if (!_validRect(bounds)) return null;
        result.add((id: subject.id, bounds: bounds));
      }
      return result;
    }

    bool fits(
      List<BattleCameraSubjectProjection>? projections, {
      double guard = 0,
    }) =>
        projections != null &&
        projections.every((subject) {
          final bounds = subject.bounds.inflate(guard);
          return bounds.left >= region.left &&
              bounds.right <= region.right &&
              bounds.top >= region.top &&
              bounds.bottom <= region.bottom &&
              blocked.every((obstacle) => !bounds.overlaps(obstacle));
        });
    final startFits = fits(project(start), guard: 2);
    bool trajectoryFits(BattleCameraPose end) {
      if (!startFits) return false;
      for (var i = 1; i < 96; i++) {
        final t = i / 96;
        if (!fits(
          project((
            eye: start.eye + (end.eye - start.eye) * t,
            aim: start.aim + (end.aim - start.aim) * t,
          )),
          guard: 2,
        )) {
          return false;
        }
      }
      return true;
    }

    BattleCameraShot? endpointFallback;
    BattleCameraShot? accept(BattleCameraPose pose, {bool ideal = false}) {
      final projections = project(pose);
      if (!fits(projections, guard: 2)) return null;
      final pathFits = trajectoryFits(pose);
      final shot = BattleCameraShot(
        eye: pose.eye,
        aim: pose.aim,
        startPose: start,
        projections: List.unmodifiable(projections!),
        fits: true,
        trajectoryFits: pathFits,
        diagnostic: pathFits
            ? (ideal
                  ? BattleCameraFramingDiagnostic.ideal
                  : BattleCameraFramingDiagnostic.reframed)
            : startFits
            ? BattleCameraFramingDiagnostic.trajectoryBlocked
            : BattleCameraFramingDiagnostic.transitionStartsOccluded,
      );
      if (pathFits || !startFits) return shot;
      endpointFallback ??= shot;
      return null;
    }

    if (policy == BattleCameraReframePolicy.holdPose) {
      return accept(start, ideal: true) ??
          failure(BattleCameraFramingDiagnostic.noSpace);
    }
    final principal = required.firstWhere(
      (subject) => subject.id == principalId,
      orElse: () => required.first,
    );
    final home = (
      eye: BattlePerspectiveCamera.homeEye,
      aim: BattlePerspectiveCamera.homeAim,
    );
    final ideal =
        intent == BattleCameraShotIntent.overview ||
            intent == BattleCameraShotIntent.group
        ? home
        : camera.idealFocusPose(
            principal.geometry.foot,
            playerSide: playerSide,
            strength: strength,
          );
    final preferred = accept(ideal, ideal: true);
    if (preferred != null) return preferred;
    for (final amplitude in [.85, .65, .4, .2, 0.0]) {
      final shot = accept((
        eye: home.eye + (ideal.eye - home.eye) * amplitude,
        aim: home.aim + (ideal.aim - home.aim) * amplitude,
      ));
      if (shot != null) return shot;
    }
    final freeRegions = _freeRegions(region, blocked);
    final forward = (home.aim - home.eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    final up = right.cross(forward);
    final centerWorld = camera.tryGroundAt(principal.geometry.foot);
    if (centerWorld == null) {
      return failure(BattleCameraFramingDiagnostic.invalidGeometry);
    }
    ({BattleCameraShot? shot, double minimumFactor}) translatedOverview(
      double factor,
    ) {
      final base = (
        eye: home.aim + (home.eye - home.aim) * factor,
        aim: home.aim,
      );
      final projected = project(base);
      if (projected == null) return (shot: null, minimumFactor: factor);
      const guard = 2.01;
      var minX = double.negativeInfinity;
      var maxX = double.infinity;
      var minY = double.negativeInfinity;
      var maxY = double.infinity;
      final scales = <double>[];
      for (var i = 0; i < required.length; i++) {
        final point = camera.tryGroundAt(required[i].geometry.foot);
        final depth = point == null ? null : probe.tryProject(point)?.depth;
        if (depth == null) return (shot: null, minimumFactor: factor);
        final scale = camera.focal / depth;
        scales.add(scale);
        final bounds = projected[i].bounds;
        minX = math.max(minX, (bounds.right - region.right + guard) / scale);
        maxX = math.min(maxX, (bounds.left - region.left - guard) / scale);
        minY = math.max(minY, (region.top + guard - bounds.top) / scale);
        maxY = math.min(maxY, (region.bottom - guard - bounds.bottom) / scale);
      }
      if (region.width <= 2 * guard || region.height <= 2 * guard) {
        return (shot: null, minimumFactor: double.infinity);
      }
      final distance = (home.eye - home.aim).length;
      final minimumFactor =
          factor +
          math.max(
            0.0,
            math.max(
              (minX - maxX) *
                  camera.focal /
                  ((region.width - 2 * guard) * distance),
              (minY - maxY) *
                  camera.focal /
                  ((region.height - 2 * guard) * distance),
            ),
          );
      if (minX > maxX || minY > maxY) {
        return (shot: null, minimumFactor: minimumFactor);
      }
      final xs = <double>{minX, maxX, 0.0.clamp(minX, maxX)};
      final ys = <double>{minY, maxY, 0.0.clamp(minY, maxY)};
      for (var i = 0; i < required.length; i++) {
        final bounds = projected[i].bounds;
        final scale = scales[i];
        for (final obstacle in blocked.where(
          (obstacle) => obstacle.overlaps(region),
        )) {
          xs.add(
            ((bounds.right - obstacle.left + guard) / scale).clamp(minX, maxX),
          );
          xs.add(
            ((bounds.left - obstacle.right - guard) / scale).clamp(minX, maxX),
          );
          ys.add(
            ((obstacle.top - guard - bounds.bottom) / scale).clamp(minY, maxY),
          );
          ys.add(
            ((obstacle.bottom + guard - bounds.top) / scale).clamp(minY, maxY),
          );
        }
      }
      final candidates =
          [
            for (final x in xs)
              for (final y in ys) Offset(x, y),
          ]..sort((a, b) {
            final distance = a.distanceSquared.compareTo(b.distanceSquared);
            if (distance != 0) return distance;
            final horizontal = a.dx.compareTo(b.dx);
            return horizontal != 0 ? horizontal : a.dy.compareTo(b.dy);
          });
      for (final candidate in candidates) {
        final endpoint = [
          for (var i = 0; i < required.length; i++)
            (
              id: projected[i].id,
              bounds: projected[i].bounds.shift(
                Offset(-candidate.dx * scales[i], candidate.dy * scales[i]),
              ),
            ),
        ];
        if (!fits(endpoint, guard: 2)) continue;
        final translation = right * candidate.dx + up * candidate.dy;
        final shot = accept((
          eye: base.eye + translation,
          aim: base.aim + translation,
        ));
        if (shot != null) return (shot: shot, minimumFactor: minimumFactor);
      }
      return (shot: null, minimumFactor: minimumFactor);
    }

    final multiSubjectOverview =
        required.length > 1 &&
        (intent == BattleCameraShotIntent.overview ||
            intent == BattleCameraShotIntent.group);
    if (multiSubjectOverview) {
      final neutral = translatedOverview(1);
      if (neutral.shot != null) return neutral.shot!;
      if (neutral.minimumFactor.isFinite && neutral.minimumFactor > 1) {
        final minimum = translatedOverview(neutral.minimumFactor + .00001);
        if (minimum.shot != null) return minimum.shot!;
      }
    }
    for (final factor in [
      1.0,
      1.25,
      1.6,
      2.2,
      3.2,
      5.0,
      8.0,
      16.0,
      32.0,
      64.0,
    ]) {
      if (multiSubjectOverview && factor > 1) {
        final translated = translatedOverview(factor);
        if (translated.shot != null) return translated.shot!;
      }
      for (final free in freeRegions) {
        final composition = free.deflate(3);
        if (composition.isEmpty) continue;
        var pose = (
          eye: home.aim + (home.eye - home.aim) * factor,
          aim: home.aim,
        );
        for (var adjustment = 0; adjustment < 4; adjustment++) {
          final projected = project(pose);
          if (projected == null) break;
          final union = projected
              .map((p) => p.bounds)
              .reduce((a, b) => a.expandToInclude(b));
          final principalProjection = probe.tryBillboardAt(
            principal.geometry.foot,
          );
          if (principalProjection == null) break;
          final focus =
              intent == BattleCameraShotIntent.attacker ||
              intent == BattleCameraShotIntent.target;
          final anchor = focus
              ? principalProjection.position +
                    (principal.geometry.focusAnchor - principal.geometry.foot) *
                        principalProjection.scale
              : union.center;
          final desired = anchor - composition.center;
          final delta = Offset(
            union.width <= composition.width
                ? desired.dx.clamp(
                    union.right - composition.right,
                    union.left - composition.left,
                  )
                : union.center.dx - composition.center.dx,
            union.height <= composition.height
                ? desired.dy.clamp(
                    union.bottom - composition.bottom,
                    union.top - composition.top,
                  )
                : union.center.dy - composition.center.dy,
          );
          final depth = probe.tryProject(centerWorld)?.depth;
          if (depth == null) break;
          final translation =
              right * (delta.dx * depth / camera.focal) -
              up * (delta.dy * depth / camera.focal);
          pose = (eye: pose.eye + translation, aim: pose.aim + translation);
        }
        final shot = accept(pose);
        if (shot != null) return shot;
      }
    }
    if (endpointFallback != null && startFits) {
      return BattleCameraShot(
        eye: start.eye,
        aim: start.aim,
        startPose: start,
        projections: List.unmodifiable(project(start)!),
        fits: true,
        trajectoryFits: true,
        diagnostic: BattleCameraFramingDiagnostic.trajectoryBlocked,
      );
    }
    return failure(BattleCameraFramingDiagnostic.noSpace);
  }

  static bool _finiteRect(Rect rect) =>
      rect.left.isFinite &&
      rect.top.isFinite &&
      rect.right.isFinite &&
      rect.bottom.isFinite;
  static bool _validRect(Rect rect) => _finiteRect(rect) && !rect.isEmpty;

  static List<Rect> _freeRegions(Rect viewport, List<Rect> obstacles) {
    var regions = [viewport];
    for (final obstacle in obstacles) {
      final next = <Rect>[];
      for (final region in regions) {
        if (!region.overlaps(obstacle)) {
          next.add(region);
          continue;
        }
        final cut = region.intersect(obstacle);
        next.addAll(
          [
            Rect.fromLTRB(region.left, region.top, region.right, cut.top),
            Rect.fromLTRB(region.left, cut.bottom, region.right, region.bottom),
            Rect.fromLTRB(region.left, region.top, cut.left, region.bottom),
            Rect.fromLTRB(cut.right, region.top, region.right, region.bottom),
          ].where((rect) => !rect.isEmpty),
        );
      }
      next.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
      regions = next.take(math.min(64, next.length)).toList();
    }
    return regions;
  }
}
