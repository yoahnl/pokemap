import 'dart:async';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

const battleStageShadowPadding = 6.0;

({int width, int height}) battleStageShadowImageSize(ui.Size ellipse) {
  if (!ellipse.width.isFinite ||
      !ellipse.height.isFinite ||
      ellipse.width <= 0 ||
      ellipse.height <= 0) {
    throw const RuntimeResourceAdmissionException('shadow_dimensions');
  }
  return (
    width: (ellipse.width + battleStageShadowPadding * 2).ceil(),
    height: (ellipse.height + battleStageShadowPadding * 2).ceil(),
  );
}

final class BattleStageDrawOrder implements Comparable<BattleStageDrawOrder> {
  const BattleStageDrawOrder({
    required this.shadow,
    required this.actorDepth,
    required this.actorIndex,
    required this.partIndex,
  });

  final bool shadow;
  final double actorDepth;
  final int actorIndex;
  final int partIndex;

  @override
  int compareTo(BattleStageDrawOrder other) {
    final phase = (shadow ? 0 : 1).compareTo(other.shadow ? 0 : 1);
    if (phase != 0) return phase;
    final depth = other.actorDepth.compareTo(actorDepth);
    if (depth != 0) return depth;
    final actor = actorIndex.compareTo(other.actorIndex);
    return actor != 0 ? actor : partIndex.compareTo(other.partIndex);
  }
}

final class BattleStageShadowMaskCache {
  BattleStageShadowMaskCache({
    required RuntimeResourceBudget resourceBudget,
    Future<ui.Image> Function(ui.Size)? generate,
    void Function(Object, StackTrace)? onError,
  }) : _budget = resourceBudget,
       _generate = generate ?? _generateMask,
       _onError = onError;

  final RuntimeResourceBudget _budget;
  final Future<ui.Image> Function(ui.Size) _generate;
  final void Function(Object, StackTrace)? _onError;
  final _images =
      <ui.Size, ({ui.Image image, RuntimeResourceReservation lease})>{};
  final _pending = <ui.Size, Object>{};
  final _failed = <ui.Size>{};
  final _inFlight = <Future<void>>{};
  final _requestsByToken = <Object, Future<void>>{};
  final _cancelled = <Future<void>>{};
  final _retired = <({ui.Image image, RuntimeResourceReservation lease})>[];
  final _retirements = <Future<void>>{};
  final _leases = <RuntimeResourceReservation>{};
  Completer<void>? _retirementPurged;
  Set<ui.Size> _active = {};
  bool _closed = false;
  int generatedMasks = 0;

  ui.Image? imageFor(ui.Size ellipse) => _images[ellipse]?.image;
  int get activeMasks => _images.length;
  int get failedMasks => _failed.length;
  int get residentBytes =>
      _leases.fold(0, (bytes, lease) => bytes + lease.residentBytes);

  Future<void> get settled async {
    while (_inFlight.isNotEmpty || _retirements.isNotEmpty) {
      await Future.wait([..._inFlight, ..._retirements]);
    }
  }

  void sync(Set<ui.Size> ellipses) {
    if (_closed) return;
    _active = Set.of(ellipses);
    _pending.removeWhere((size, token) {
      if (ellipses.contains(size)) return false;
      final request = _requestsByToken[token];
      if (request != null) _cancelled.add(request);
      return true;
    });
    _failed.removeWhere((size) => !ellipses.contains(size));
    for (final size
        in _images.keys.where((size) => !ellipses.contains(size)).toList()) {
      _retired.add(_images.remove(size)!);
    }
    if (_retired.isNotEmpty) _retirementPurged ??= Completer<void>();
    for (final size in ellipses) {
      if (_images.containsKey(size) ||
          _pending.containsKey(size) ||
          _failed.contains(size)) {
        continue;
      }
      final token = Object();
      _pending[size] = token;
      late final Future<void> request;
      request = _load(size, token).whenComplete(() {
        _inFlight.remove(request);
        _cancelled.remove(request);
        _requestsByToken.remove(token);
      });
      _inFlight.add(request);
      _requestsByToken[token] = request;
    }
  }

  bool _isCurrent(ui.Size size, Object token) =>
      !_closed && _active.contains(size) && identical(_pending[size], token);

  Future<void> _load(ui.Size size, Object token) async {
    RuntimeResourceReservation? lease;
    ui.Image? image;
    try {
      if (_cancelled.isNotEmpty) await Future.wait(_cancelled.toList());
      final retirement = _retirementPurged;
      if (retirement != null) await retirement.future;
      if (!_isCurrent(size, token)) return;
      final dimensions = battleStageShadowImageSize(size);
      final bytes = runtimeImageRgbaByteLength(
        dimensions.width,
        dimensions.height,
        maximumBytes: _budget.profile.maximumResidentBytes,
      );
      lease = await _budget.acquire(
        residentBytes: bytes,
        transientBytes: bytes,
        isCurrent: () => _isCurrent(size, token),
      );
      _leases.add(lease);
      lease.ensureCurrent();
      image = await _generate(size);
      lease.ensureCurrent();
      if (image.width != dimensions.width ||
          image.height != dimensions.height) {
        throw StateError('Generated shadow dimensions differ from admission.');
      }
      lease.commit();
      _images[size] = (image: image, lease: lease);
      generatedMasks++;
      image = null;
      lease = null;
    } catch (error, stack) {
      if (_isCurrent(size, token)) {
        _failed.add(size);
        _onError?.call(error, stack);
      }
    } finally {
      image?.dispose();
      if (lease != null) _leases.remove(lease);
      lease?.release();
      if (identical(_pending[size], token)) _pending.remove(size);
    }
  }

  void releaseRetiredAfter(Future<void> Function(ui.Image) imports) {
    if (_retired.isEmpty) return;
    final retired = List.of(_retired);
    _retired.clear();
    late final Future<void> retirement;
    retirement =
        Future.wait([for (final entry in retired) imports(entry.image)])
            .whenComplete(() {
              for (final entry in retired) {
                entry.image.dispose();
                _leases.remove(entry.lease);
                entry.lease.release();
              }
              _retirements.remove(retirement);
              if (_retirements.isEmpty && _retired.isEmpty) {
                final purged = _retirementPurged;
                _retirementPurged = null;
                purged?.complete();
              }
            });
    _retirements.add(retirement);
  }

  void close({required Future<void> Function(ui.Image) imports}) {
    if (_closed) return;
    _closed = true;
    _active.clear();
    _pending.clear();
    _failed.clear();
    _retired.addAll(_images.values);
    _images.clear();
    releaseRetiredAfter(imports);
  }

  static Future<ui.Image> _generateMask(ui.Size ellipse) async {
    final dimensions = battleStageShadowImageSize(ellipse);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(dimensions.width / 2, dimensions.height / 2),
        width: ellipse.width,
        height: ellipse.height,
      ),
      ui.Paint()
        ..color = const ui.Color(0xffffffff)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.5),
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(dimensions.width, dimensions.height);
    } finally {
      picture.dispose();
    }
  }
}
