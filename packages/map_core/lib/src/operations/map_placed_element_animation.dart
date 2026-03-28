import '../models/enums.dart';
import '../models/map_data.dart';

const int defaultPlacedElementAnimationFrameDurationMs = 200;

int stableHash32(String input) {
  var hash = 0x811C9DC5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash & 0x7fffffff;
}

int resolvePlacedElementAnimationFrameIndex({
  required List<int> frameDurationsMs,
  required double elapsedMs,
  MapPlacedElementAnimation? animation,
  int deterministicSeed = 0,
}) {
  if (frameDurationsMs.isEmpty) {
    return 0;
  }
  if (frameDurationsMs.length == 1) {
    return 0;
  }
  final normalizedDurations = frameDurationsMs
      .map((value) =>
          value > 0 ? value : defaultPlacedElementAnimationFrameDurationMs)
      .toList(growable: false);
  final config = animation;
  if (config == null || !config.enabled) {
    return 0;
  }
  final speed = config.speed <= 0 ? 1.0 : config.speed;
  final sequence = _buildSequence(
    frameDurationsMs: normalizedDurations,
    mode: config.mode,
  );
  if (sequence.indices.isEmpty || sequence.totalDurationMs <= 0) {
    return 0;
  }
  final startOffsetMs = _computeStartOffsetMs(
    config: config,
    totalDurationMs: sequence.totalDurationMs,
    deterministicSeed: deterministicSeed,
  );
  if (!config.autoplay) {
    return _resolveFrameIndexAtOffset(
      sequence: sequence,
      offsetMs: startOffsetMs,
    );
  }
  final elapsedScaled = elapsedMs * speed;
  final offset = elapsedScaled + startOffsetMs;
  return _resolveFrameIndexAtOffset(sequence: sequence, offsetMs: offset);
}

List<int> normalizeElementFrameDurationsMs(List<int?> rawDurations) {
  if (rawDurations.isEmpty) {
    return const [defaultPlacedElementAnimationFrameDurationMs];
  }
  return rawDurations
      .map(
        (value) => value != null && value > 0
            ? value
            : defaultPlacedElementAnimationFrameDurationMs,
      )
      .toList(growable: false);
}

double _computeStartOffsetMs({
  required MapPlacedElementAnimation config,
  required int totalDurationMs,
  required int deterministicSeed,
}) {
  var offset = config.startOffsetMs ?? 0;
  if (!config.randomStart || totalDurationMs <= 0) {
    return offset;
  }
  final unit = ((deterministicSeed & 0x7fffffff) % 1000003) / 1000003.0;
  offset += unit * totalDurationMs;
  return offset;
}

int _resolveFrameIndexAtOffset({
  required _AnimationSequence sequence,
  required double offsetMs,
}) {
  final total = sequence.totalDurationMs;
  if (total <= 0 || sequence.indices.isEmpty) {
    return 0;
  }
  final mod = ((offsetMs % total) + total) % total;
  var cursor = mod;
  for (var i = 0; i < sequence.indices.length; i++) {
    final duration = sequence.durationsMs[i];
    if (cursor < duration) {
      return sequence.indices[i];
    }
    cursor -= duration;
  }
  return sequence.indices.last;
}

_AnimationSequence _buildSequence({
  required List<int> frameDurationsMs,
  required MapPlacedElementAnimationMode mode,
}) {
  final frameCount = frameDurationsMs.length;
  if (frameCount <= 1 || mode == MapPlacedElementAnimationMode.none) {
    return _AnimationSequence(
      indices: const [0],
      durationsMs: [frameDurationsMs.first],
    );
  }
  switch (mode) {
    case MapPlacedElementAnimationMode.none:
      return _AnimationSequence(
        indices: const [0],
        durationsMs: [frameDurationsMs.first],
      );
    case MapPlacedElementAnimationMode.loop:
      final indices = List<int>.generate(frameCount, (i) => i, growable: false);
      final durations = List<int>.from(frameDurationsMs, growable: false);
      return _AnimationSequence(indices: indices, durationsMs: durations);
    case MapPlacedElementAnimationMode.pingPong:
      if (frameCount == 2) {
        return _AnimationSequence(
          indices: const [0, 1],
          durationsMs: [frameDurationsMs[0], frameDurationsMs[1]],
        );
      }
      final indices = <int>[];
      final durations = <int>[];
      for (var i = 0; i < frameCount; i++) {
        indices.add(i);
        durations.add(frameDurationsMs[i]);
      }
      for (var i = frameCount - 2; i >= 1; i--) {
        indices.add(i);
        durations.add(frameDurationsMs[i]);
      }
      return _AnimationSequence(indices: indices, durationsMs: durations);
  }
}

class _AnimationSequence {
  const _AnimationSequence({
    required this.indices,
    required this.durationsMs,
  });

  final List<int> indices;
  final List<int> durationsMs;

  int get totalDurationMs {
    var total = 0;
    for (final duration in durationsMs) {
      total += duration;
    }
    return total;
  }
}
