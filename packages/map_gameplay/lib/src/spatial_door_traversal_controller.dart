import 'dart:async';
import 'dart:math' as math;

import 'package:map_core/map_core.dart';

enum SpatialDoorTraversalPhase {
  idle,
  openingDeparture,
  steppingDeparture,
  fadingOut,
  waitingTransfer,
  fadingInArrival,
  steppingArrival,
  closingArrival,
  completed,
  cancelled,
}

final class SpatialDoorTraversalBinding {
  SpatialDoorTraversalBinding({
    required this.mapId,
    required this.instance,
    required this.openAnimationIndex,
    required this.closeAnimationIndex,
    required this.openDurationSeconds,
    required this.closeDurationSeconds,
    required this.exitPos,
  }) {
    if (mapId.isEmpty ||
        openAnimationIndex < 0 ||
        closeAnimationIndex < 0 ||
        !openDurationSeconds.isFinite ||
        openDurationSeconds <= 0 ||
        !closeDurationSeconds.isFinite ||
        closeDurationSeconds <= 0) {
      throw ArgumentError('Invalid native door animation binding.');
    }
  }

  final String mapId;
  final SpatialModelInstance instance;
  final int openAnimationIndex, closeAnimationIndex;
  final double openDurationSeconds, closeDurationSeconds;
  final GridPos exitPos;
}

final class SpatialDoorTraversalController {
  static const fadeDurationSeconds = 6 / 30;
  static const stepDurationSeconds = 8 / 30;

  SpatialDoorTraversalPhase phase = SpatialDoorTraversalPhase.idle;
  SpatialDoorTraversalBinding? _departure, _arrival;
  GridPos? _departurePos, _arrivalPos;
  ({double x, double z})? _departureStart;
  double _elapsed = 0;
  double _sourceWalkElapsed = 0;
  double _arrivalWalkElapsed = 0;
  double _departureZoomElapsed = 0;
  bool _transferred = false;
  bool _arrivalFirstFramePending = false;
  MapWarpTransition _transition = const MapWarpTransition();
  bool _explicitTransition = false;

  MapWarpTransition get transition => _transition;
  bool get revealing => _transferred;
  bool get _usesTransition =>
      (_hasDoor || _explicitTransition) &&
      _transition.type != MapWarpTransitionType.none;
  double get _fadeSeconds => _usesTransition ? _transition.durationSeconds : 0;
  Completer<bool>? _ready, _finished;

  String? get cameraMapId =>
      !isActive || _transition.type != MapWarpTransitionType.hgss
          ? null
          : _transferred
              ? _arrival?.mapId
              : _departure?.mapId;

  ({double x, double z})? get cameraAnchor =>
      cameraMapId == null || _transferred ? null : _departureStart;

  double get cameraMagnification {
    if (cameraMapId == null) return 1;
    final approachSeconds =
        (_departure?.openDurationSeconds ?? 0) + stepDurationSeconds;
    final progress = (_departureZoomElapsed / approachSeconds).clamp(0.0, 1.0);
    final easedProgress = progress * progress * (3 - 2 * progress);
    final offset = !_transferred
        ? 108 * easedProgress
        : phase == SpatialDoorTraversalPhase.fadingInArrival
            ? (96 * (1 - _elapsed / fadeDurationSeconds)).clamp(0.0, 96.0)
            : 0.0;
    final angle = 1473 * math.pi / 32768;
    return math.tan(angle) / math.tan((1473 - offset) * math.pi / 32768);
  }

  bool get isActive =>
      phase != SpatialDoorTraversalPhase.idle &&
      phase != SpatialDoorTraversalPhase.completed &&
      phase != SpatialDoorTraversalPhase.cancelled;
  Future<bool> get readyToTransfer => _ready!.future;
  Future<bool> get finished => _finished!.future;
  String? get playerPoseMapId => playerPose == null
      ? null
      : _transferred
          ? _arrival?.mapId
          : _departure?.mapId;
  bool get _hasDoor => _departure != null || _arrival != null;
  bool get heroVisible => switch (phase) {
        SpatialDoorTraversalPhase.fadingOut => !_hasDoor,
        SpatialDoorTraversalPhase.waitingTransfer => !_hasDoor,
        SpatialDoorTraversalPhase.fadingInArrival => _arrival == null,
        _ => true,
      };
  double get blackoutOpacity => !_usesTransition
      ? 0
      : switch (phase) {
          SpatialDoorTraversalPhase.fadingOut =>
            (_elapsed / _fadeSeconds).clamp(0, 1),
          SpatialDoorTraversalPhase.waitingTransfer => 1,
          SpatialDoorTraversalPhase.fadingInArrival =>
            (1 - _elapsed / _fadeSeconds).clamp(0, 1),
          _ => 0,
        };

  bool start({
    SpatialDoorTraversalBinding? departure,
    SpatialDoorTraversalBinding? arrival,
    GridPos? departurePos,
    ({double x, double z})? departureStart,
    GridPos? arrivalPos,
    MapWarpTransition? transition,
  }) {
    if (isActive) return false;
    bool adjacent(GridPos a, GridPos b) =>
        (a.x - b.x).abs() + (a.y - b.y).abs() == 1;
    if (departure != null &&
        (departurePos == null || !adjacent(departurePos, departure.exitPos))) {
      throw ArgumentError(
          'Native door departure requires a cardinal threshold.');
    }
    final sourceStart = departureStart ??
        (departure == null
            ? null
            : (x: departure.exitPos.x + .5, z: departure.exitPos.y + .5));
    if (departure != null &&
        (sourceStart == null ||
            !sourceStart.x.isFinite ||
            !sourceStart.z.isFinite ||
            sourceStart.x.floor() != departure.exitPos.x ||
            sourceStart.z.floor() != departure.exitPos.y)) {
      throw ArgumentError('Native door departure must start in its exit cell.');
    }
    if (arrival != null &&
        (arrivalPos == null || !adjacent(arrivalPos, arrival.exitPos))) {
      throw ArgumentError(
          'Native door arrival requires one cardinal exit step.');
    }
    _transition = transition ?? const MapWarpTransition();
    _explicitTransition = transition != null;
    _departure = departure;
    _arrival = arrival;
    _departurePos = departurePos;
    _departureStart = sourceStart;
    _arrivalPos = arrivalPos;
    _elapsed =
        _sourceWalkElapsed = _arrivalWalkElapsed = _departureZoomElapsed = 0;
    _transferred = false;
    _arrivalFirstFramePending = false;
    _ready = Completer<bool>();
    _finished = Completer<bool>();
    phase = departure != null
        ? SpatialDoorTraversalPhase.openingDeparture
        : _usesTransition
            ? SpatialDoorTraversalPhase.fadingOut
            : SpatialDoorTraversalPhase.waitingTransfer;
    if (phase == SpatialDoorTraversalPhase.waitingTransfer) {
      _ready!.complete(true);
    }
    return true;
  }

  void transferCompleted() {
    if (phase != SpatialDoorTraversalPhase.waitingTransfer) {
      throw StateError('The native door transfer has no active lease.');
    }
    _transferred = true;
    _arrivalFirstFramePending = true;
    _elapsed = 0;
    phase = (_arrival != null || _usesTransition)
        ? SpatialDoorTraversalPhase.fadingInArrival
        : SpatialDoorTraversalPhase.completed;
    if (phase == SpatialDoorTraversalPhase.completed) _finished!.complete(true);
  }

  void update(double dt, {bool paused = false}) {
    if (!isActive ||
        paused ||
        !dt.isFinite ||
        dt <= 0 ||
        phase == SpatialDoorTraversalPhase.waitingTransfer) {
      return;
    }
    if (_arrivalFirstFramePending) {
      _arrivalFirstFramePending = false;
      return;
    }
    final duration = switch (phase) {
      SpatialDoorTraversalPhase.openingDeparture =>
        _departure!.openDurationSeconds,
      SpatialDoorTraversalPhase.steppingDeparture ||
      SpatialDoorTraversalPhase.steppingArrival =>
        stepDurationSeconds,
      SpatialDoorTraversalPhase.fadingOut => _fadeSeconds,
      SpatialDoorTraversalPhase.fadingInArrival =>
        (_arrival?.openDurationSeconds ?? 0) > _fadeSeconds
            ? _arrival!.openDurationSeconds
            : _fadeSeconds,
      SpatialDoorTraversalPhase.closingArrival =>
        _arrival!.closeDurationSeconds,
      _ => throw StateError('Invalid native door presentation phase.'),
    };
    final admitted = dt.clamp(0.0, duration / 2);
    if (!_transferred &&
        (phase == SpatialDoorTraversalPhase.openingDeparture ||
            phase == SpatialDoorTraversalPhase.steppingDeparture)) {
      _departureZoomElapsed += admitted.clamp(0.0, duration - _elapsed);
    }
    _elapsed += admitted;
    if (_elapsed + duration * 1e-7 >= duration) _elapsed = duration;
    if (phase == SpatialDoorTraversalPhase.steppingDeparture) {
      _sourceWalkElapsed = _elapsed;
    } else if (phase == SpatialDoorTraversalPhase.steppingArrival) {
      _arrivalWalkElapsed = _elapsed;
    }
    if (_elapsed < duration) return;
    _elapsed = 0;
    switch (phase) {
      case SpatialDoorTraversalPhase.openingDeparture:
        phase = SpatialDoorTraversalPhase.steppingDeparture;
      case SpatialDoorTraversalPhase.steppingDeparture:
        phase = SpatialDoorTraversalPhase.fadingOut;
      case SpatialDoorTraversalPhase.fadingOut:
        phase = SpatialDoorTraversalPhase.waitingTransfer;
        _ready!.complete(true);
      case SpatialDoorTraversalPhase.fadingInArrival:
        phase = _arrival == null
            ? SpatialDoorTraversalPhase.completed
            : SpatialDoorTraversalPhase.steppingArrival;
        if (_arrival == null) _finished!.complete(true);
      case SpatialDoorTraversalPhase.steppingArrival:
        phase = SpatialDoorTraversalPhase.closingArrival;
      case SpatialDoorTraversalPhase.closingArrival:
        phase = SpatialDoorTraversalPhase.completed;
        _finished!.complete(true);
      default:
        throw StateError('Invalid native door presentation transition.');
    }
  }

  SpatialModelRuntimeState? poseFor(String mapId, String instanceId) {
    if (phase == SpatialDoorTraversalPhase.idle ||
        phase == SpatialDoorTraversalPhase.cancelled) {
      return null;
    }
    final arrival = _arrival;
    if (arrival != null &&
        (_transferred ||
            _departure?.mapId != mapId ||
            _departure?.instance.id != instanceId) &&
        arrival.mapId == mapId &&
        arrival.instance.id == instanceId) {
      final closing = phase == SpatialDoorTraversalPhase.closingArrival ||
          phase == SpatialDoorTraversalPhase.completed;
      final progress = switch (phase) {
        SpatialDoorTraversalPhase.fadingInArrival =>
          _elapsed / arrival.openDurationSeconds,
        SpatialDoorTraversalPhase.steppingArrival => 1.0,
        SpatialDoorTraversalPhase.closingArrival =>
          _elapsed / arrival.closeDurationSeconds,
        SpatialDoorTraversalPhase.completed => 1.0,
        _ => 0.0,
      };
      return SpatialModelRuntimeState(
          modelId: arrival.instance.modelId,
          animationIndex: closing
              ? arrival.closeAnimationIndex
              : arrival.openAnimationIndex,
          normalizedTime: progress.clamp(0, 1),
          blocksMovement: false);
    }
    final departure = _departure;
    if (!_transferred &&
        departure != null &&
        departure.mapId == mapId &&
        departure.instance.id == instanceId) {
      return SpatialModelRuntimeState(
          modelId: departure.instance.modelId,
          animationIndex: departure.openAnimationIndex,
          normalizedTime: phase == SpatialDoorTraversalPhase.openingDeparture
              ? (_elapsed / departure.openDurationSeconds).clamp(0, 1)
              : 1,
          blocksMovement: phase == SpatialDoorTraversalPhase.openingDeparture &&
              departure.instance.blocksMovement);
    }
    return null;
  }

  ({
    double x,
    double z,
    EntityFacing facing,
    bool moving,
    double animationSeconds
  })? get playerPose {
    if (phase == SpatialDoorTraversalPhase.idle ||
        phase == SpatialDoorTraversalPhase.cancelled) {
      return null;
    }
    final departure = _departure, departurePos = _departurePos;
    final departureStart = _departureStart;
    if (!_transferred &&
        departure != null &&
        departurePos != null &&
        departureStart != null) {
      final progress =
          (_sourceWalkElapsed / stepDurationSeconds).clamp(0.0, 1.0);
      return (
        x: departureStart.x +
            (departurePos.x + .5 - departureStart.x) * progress,
        z: departureStart.z +
            (departurePos.y + .5 - departureStart.z) * progress,
        facing: _facing(departurePos.x - departure.exitPos.x,
            departurePos.y - departure.exitPos.y),
        moving: phase == SpatialDoorTraversalPhase.steppingDeparture,
        animationSeconds: _sourceWalkElapsed,
      );
    }
    final arrival = _arrival, from = _arrivalPos;
    if (!_transferred || arrival == null || from == null) return null;
    final dx = arrival.exitPos.x - from.x, dz = arrival.exitPos.y - from.y;
    final progress =
        (_arrivalWalkElapsed / stepDurationSeconds).clamp(0.0, 1.0);
    return (
      x: from.x + .5 + dx * progress,
      z: from.y + .5 + dz * progress,
      facing: _facing(dx, dz),
      moving: phase == SpatialDoorTraversalPhase.steppingArrival,
      animationSeconds: _arrivalWalkElapsed,
    );
  }

  EntityFacing _facing(int dx, int dz) => dx > 0
      ? EntityFacing.east
      : dx < 0
          ? EntityFacing.west
          : dz > 0
              ? EntityFacing.south
              : EntityFacing.north;

  void cancel() {
    if (!isActive) return;
    phase = SpatialDoorTraversalPhase.cancelled;
    if (!_ready!.isCompleted) _ready!.complete(false);
    if (!_finished!.isCompleted) _finished!.complete(false);
  }

  void clear() {
    cancel();
    phase = SpatialDoorTraversalPhase.idle;
    _departure = _arrival = null;
    _departurePos = _arrivalPos = null;
    _departureStart = null;
  }
}
