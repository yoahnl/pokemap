final class FineMaskPerformanceSpanName {
  const FineMaskPerformanceSpanName._();

  static const readback = 'mask.readback';
  static const pointerMove = 'mask.pointer_move';
  static const commit = 'mask.commit';
  static const build = 'mask.build';
  static const paint = 'mask.paint';
}

final class FineMaskPerformanceBudget {
  const FineMaskPerformanceBudget._();

  static const schemaVersion = 1;
  static const pointerMove1024P95Us = 8000;
  static const paint1024P95Us = 16700;
  static const frameTimingPolicy = 'observation';
}
