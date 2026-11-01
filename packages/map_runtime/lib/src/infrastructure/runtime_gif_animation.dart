import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'tile_image_loader.dart';

typedef RuntimeGifCodecFactory = Future<ui.Codec> Function(Uint8List bytes);

final class RuntimeGifTimeline {
  const RuntimeGifTimeline._(this._durations, this.repetitionCount);

  final List<Duration> _durations;
  final int repetitionCount;

  int get frameCount => _durations.length;

  int frameIndexAt(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError.value(elapsed, 'elapsed');
    var total = 0;
    for (var i = 0; i < _durations.length; i++) {
      final duration = _durations[i].inMicroseconds;
      if (duration == 0) {
        if (elapsed.inMicroseconds < total) break;
        return i;
      }
      total += duration;
    }
    if (total == 0) return 0;
    final elapsedMicros = elapsed.inMicroseconds;
    if (repetitionCount >= 0 && elapsedMicros ~/ total > repetitionCount) {
      return frameCount - 1;
    }
    var position = elapsedMicros % total;
    for (var i = 0; i < _durations.length; i++) {
      final duration = _durations[i].inMicroseconds;
      if (duration == 0 || position < duration) return i;
      position -= duration;
    }
    return frameCount - 1;
  }
}

final class RuntimeGifAnimation {
  RuntimeGifAnimation._(
    this._frames,
    this.timeline,
    this._reservation,
    this.resourceBudget,
  );

  final List<ui.Image> _frames;
  final RuntimeGifTimeline timeline;
  final RuntimeResourceReservation _reservation;
  final RuntimeResourceBudget resourceBudget;
  bool _disposed = false;

  int get frameCount => _frames.length;
  int get repetitionCount => timeline.repetitionCount;
  bool get isDisposed => _disposed;

  ui.Image frameByIndex(int index) {
    if (_disposed) throw StateError('GIF animation is disposed');
    return _frames[index];
  }

  ui.Image frameAt(Duration elapsed) {
    if (_disposed) throw StateError('GIF animation is disposed');
    return _frames[timeline.frameIndexAt(elapsed)];
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      for (final frame in _frames) {
        frame.dispose();
      }
    } finally {
      _reservation.release();
    }
  }
}

Future<RuntimeGifAnimation> decodeRuntimeGif(
  Uint8List bytes, {
  RuntimeResourceBudget? resourceBudget,
  bool Function()? isCurrent,
  int maximumFrames = 256,
  RuntimeGifCodecFactory? codecFactory,
}) async {
  if (maximumFrames < 1 || maximumFrames > 512) {
    throw ArgumentError.value(maximumFrames, 'maximumFrames');
  }
  if (!_isGif(bytes)) throw const FormatException('Invalid GIF header');
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  if (bytes.isEmpty || bytes.length > budget.profile.maximumEncodedBytes) {
    throw const RuntimeResourceAdmissionException('encoded_bytes');
  }
  final reservation = await budget.acquire(
    transientBytes: bytes.length * 2,
    isCurrent: isCurrent,
  );
  ui.Codec? codec;
  final frames = <ui.Image>[];
  final durations = <Duration>[];
  try {
    reservation.ensureCurrent();
    final ownedBytes = Uint8List.fromList(bytes);
    if (!_isGif(ownedBytes)) throw const FormatException('Invalid GIF header');
    final dimensions = await inspectRuntimeImageDimensions(ownedBytes);
    final pixels = runtimeImageRgbaByteLength(
      dimensions.width,
      dimensions.height,
      maximumBytes: reservation.profile.maximumResidentBytes,
    );
    reservation.resize(
      residentBytes: 0,
      transientBytes: ownedBytes.length * 2 + pixels * 2,
    );
    codec = await (codecFactory ?? ui.instantiateImageCodec)(ownedBytes);
    reservation.ensureCurrent();
    final count = codec.frameCount;
    if (count < 1 || count > maximumFrames) {
      throw const RuntimeResourceAdmissionException('gif_frame_count');
    }
    if (count > reservation.profile.maximumResidentBytes ~/ pixels) {
      throw const RuntimeResourceAdmissionException('gif_frame_bytes');
    }
    reservation.resize(
      residentBytes: pixels * count,
      transientBytes: ownedBytes.length * 2 + pixels * 2,
    );
    final repetitionCount = codec.repetitionCount;
    if (repetitionCount < -1) {
      throw const FormatException('Invalid GIF repetition count');
    }
    for (var i = 0; i < count; i++) {
      reservation.ensureCurrent();
      final frame = await codec.getNextFrame();
      frames.add(frame.image);
      if (frame.image.width != dimensions.width ||
          frame.image.height != dimensions.height ||
          frame.duration.isNegative) {
        throw const RuntimeResourceAdmissionException('gif_frame_dimensions');
      }
      durations.add(frame.duration);
    }
    reservation.ensureCurrent();
    reservation.commit();
    return RuntimeGifAnimation._(
      List.unmodifiable(frames),
      RuntimeGifTimeline._(List.unmodifiable(durations), repetitionCount),
      reservation,
      budget,
    );
  } catch (_) {
    for (final frame in frames) {
      frame.dispose();
    }
    reservation.release();
    rethrow;
  } finally {
    codec?.dispose();
  }
}

bool _isGif(Uint8List bytes) =>
    bytes.length >= 6 &&
    bytes[0] == 0x47 &&
    bytes[1] == 0x49 &&
    bytes[2] == 0x46 &&
    bytes[3] == 0x38 &&
    (bytes[4] == 0x37 || bytes[4] == 0x39) &&
    bytes[5] == 0x61;
