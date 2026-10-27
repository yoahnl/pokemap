import 'dart:async';

final class SpatialCooperativeBudget {
  SpatialCooperativeBudget({
    this.slice = const Duration(milliseconds: 6),
    Future<void> Function()? yieldToFrames,
  }) : _yield = yieldToFrames ?? _nextEvent;

  final Duration slice;
  final Future<void> Function() _yield;
  final _watch = Stopwatch()..start();
  int yields = 0;

  bool get exhausted => _watch.elapsed >= slice;

  Future<void> yieldToFrames() async {
    yields++;
    await _yield();
    _watch
      ..reset()
      ..start();
  }

  static Future<void> _nextEvent() {
    final next = Completer<void>();
    Zone.root.createTimer(Duration.zero, next.complete);
    return next.future;
  }
}

Future<List<T>?> spatialCollectSteps<T extends Object>(
  Iterable<T?> steps, {
  required SpatialCooperativeBudget budget,
  required bool Function() isCurrent,
}) async {
  final results = <T>[];
  for (final step in steps) {
    if (step != null) results.add(step);
    if (!budget.exhausted) continue;
    await budget.yieldToFrames();
    if (!isCurrent()) return null;
  }
  return results;
}
